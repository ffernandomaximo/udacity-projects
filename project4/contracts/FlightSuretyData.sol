// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Roles
import "./Roles.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;


    /********************************************************************************************/
    /*                                  DATA VARIABLES - ROLES                                  */
    /********************************************************************************************/
    using Roles for Roles.Role;

    Roles.Role private registers;
    Roles.Role private controllers;
    Roles.Role private participants;
    Roles.Role private candidates;            

    function register(address _address) public {
        require(!isRegistered(_address), "ERROR: CALLER IS ALREADY REGISTERED");
        registers.add(_address);
    }

    function addController(address _address) public {
        require(!isController(_address), "ERROR: CALLER IS ALREADY A CONTROLLER");
        controllers.add(_address);
    }

    function addParticipant(address _address) public {
        require(!isParticipant(_address), "ERROR: CALLER IS ALREADY A PARTICIPANT");
        participants.add(_address);
    }
    
    function addCandidate(address _address) public {
        require(!isCandidate(_address), "ERROR: CALLER IS ALREADY A CANDIDATE");
        candidates.add(_address);
    }


    /********************************************************************************************/
    /*                                 DATA VARIABLES - AIRLINE                                 */
    /********************************************************************************************/
    address payable contractOwner;                                      // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;                                    // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    address[] multiCalls = new address[](0);
    uint M = 3;
    
    struct Airline {
        uint    aId;
        string  aName;
        address payable aAddress;
        bool    aRegistered;
        bool    aParticipant;
        bool    aController;
    }
    mapping(uint => Airline) private airlines;
    mapping(address => uint) private airlinesReverse;
    uint aCounter;
    uint participantFund = 10 ether;

    /********************************************************************************************/
    /*                                  DATA VARIABLES - VOTING                                 */
    /********************************************************************************************/
    struct Voter {
        uint weight; // WEIGHT IS ACCUMULATED BY DELEGATION
        bool voted;  // IF TRUE, THAT PERSON ALREADY VOTED
        address delegate; // PERSON DELEGATED TO
        address vote;   // ADDRESS OF THE VOTED PROPOSAL
    }
    // THIS IS A TYPE FOR A SINGLE PROPOSAL.
    struct Proposal {
        address pAddress;  //ADDRESS
        string pName;   // SHORT NAME
        uint pVoteCount; // NUMBER OF ACCUMULATED VOTES
    }
    Proposal[] public proposals;
    uint pCounter;
    mapping(address => address[]) public voters;


    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    // struct Passenger {
    //     uint    pId;
    //     address pAddress;
    // }
    // mapping(uint => Passenger) private passengers;


    /********************************************************************************************/
    /*                                       CONSTRUCTOR DEFINITION                             */
    /********************************************************************************************/    
    /* The deploying account becomes contractOwner */
    constructor() {
        contractOwner = payable(msg.sender);
        aCounter = 1;
        address _firsAAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
        string memory _firstName = "Air New Zealand";
        airlines[aCounter] = Airline(
            {
                aId: aCounter,
                aName: _firstName,
                aAddress: payable(_firsAAddress),
                aRegistered: true,
                aParticipant: true,
                aController: true
            });
        register(_firsAAddress);
        addController(_firsAAddress);

        //voters[_firsAAddress].weight = 1;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Registration(uint aId);
    event Candidate(string pName);
    event Funding(uint aId);
    event Acquisition();
    event Payment();

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireIsOperational() {
        require(operational, "CONTRACT IS CURRENTLY NOT OPERATIONAL");
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address, "CALLER IS NOT ALLOWED TO EXECUTE FUNCTION"); 
        _;
    }

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "CALLER IS NOT CONTRACT OWNER");
        _;
    }

    modifier requireController() {
        require(msg.sender == contractOwner || controllers.has(msg.sender), "CALLER IS NOT CONTROLLER");
        _;
    }

    modifier paidEnough(uint _price) { 
        require(msg.value >= _price, "AMOUNT IS NOT ENOUGHT"); 
        _;
    }
  
    modifier checkValue() {
        uint amountToReturn = msg.value - participantFund;
        contractOwner.transfer(amountToReturn);
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function kill() public requireContractOwner() {
        if (msg.sender == contractOwner) {
            selfdestruct(contractOwner);
        }
    }

    function isOperational() public view returns(bool) {
        return operational;
    }
    
    function isRegistered(address _address) public view returns(bool) {
        return registers.has(_address); //"ERROR: AIRLINE IS NOT REGISTERED");
    }

    function isController(address _address) public view returns(bool) {
        return controllers.has(_address); // "ERROR: AIRLINE IS NOT CONTROLLER");
    }

    function isParticipant(address _address) public view returns(bool) {
        return participants.has(_address); 
    }

    function isCandidate(address _address) public view returns(bool) {
        return candidates.has(_address);
    }

    /********************************************************************************************/
    /*                                  OPERATIONAL STATUS CONTROL                              */
    /********************************************************************************************/

    function setOperatingStatus(bool mode) external requireController() {
        require(mode != operational, "NEW MODE MUST BE DIFERENT THAN THE EXISITNG");
        bool isDuplicate = false;
        for(uint c = 0; c < multiCalls.length; c++) {
            if (multiCalls[c] == msg.sender) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "CALLER HAS ALREADY CALLED THIS FUNCTION");
        multiCalls.push(msg.sender);
        if (multiCalls.length >= M) {
            operational = mode;
            multiCalls = new address[](0);
        }
    }


    /********************************************************************************************/
    /*                            SMART CONTRACT REGISTER FUNCTIONS                             */
    /********************************************************************************************/
    function registerAirline(string memory _aName, address _aAddress) external requireIsOperational() {
        require(!isRegistered(_aAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        if(aCounter < 4) {
            require(msg.sender == contractOwner || isController(msg.sender), "CALLER IS NOT CONTROLLER");
            aCounter ++;
            airlines[aCounter] = Airline(
                {
                    aId: aCounter,
                    aName: _aName,
                    aAddress: payable(_aAddress),                    
                    aRegistered: true,
                    aParticipant: false,
                    aController: false
                }
            );
            airlinesReverse[_aAddress] = aCounter; 
            register(_aAddress);
            airlines[aCounter].aController = true;
            addController(_aAddress);
            
            emit Registration(aCounter);

        }
        else {
            candidateAirline(_aName, _aAddress);
        }
    }

    function candidateAirline(string memory _cName, address _cAddress) internal requireIsOperational() {
        require(!isRegistered(_cAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        require(!isCandidate(_cAddress), "ERROR: AIRLINE IS ALREADY A CANDIDATE");
        proposals.push(Proposal({
            pAddress: _cAddress,
            pName: _cName,
            pVoteCount: 0
        }));
        addCandidate(_cAddress);
     
        emit Candidate(_cName);
    }

    function fund() public payable paidEnough(participantFund) checkValue() {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(!isParticipant(msg.sender), "ERROR: CALLER IS ALREADY A PARTICIPANT");
        uint i = airlinesReverse[msg.sender];
        contractOwner.transfer(participantFund);
        airlines[i].aParticipant = true;
        addParticipant(msg.sender);
    
        emit Funding(i);
    }


    /********************************************************************************************/
    /*                              SMART CONTRACT VOTING FUNCTIONS                             */
    /********************************************************************************************/
    function vote(string memory _vName, address _vAddress) public {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(isCandidate(_vAddress), "ERROR: AIRLINE VOTED IS NOT A CANDIDATE");
        bool found = false;
        for (uint v = 0; v < voters[msg.sender].length; v++) {
            if(voters[msg.sender][v] == _vAddress){
                found = true;
                revert("ERROR: CALLER ALREADY VOTED FOR THIS AIRLINE");
            }
        }
        if(!found){
            voters[msg.sender].push(_vAddress);
        }
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].pAddress == _vAddress) {
                proposals[p].pVoteCount += 1;
                if((proposals[p].pVoteCount / aCounter)*100 >= 50){
                    registerAirlineVote(_vName, _vAddress);
                }
                break;
            }
        }
    }

    function registerAirlineVote(string memory _aName2, address _aAddress2) internal requireIsOperational() {
        require(!isRegistered(_aAddress2), "ERROR: AIRLINE IS ALREADY REGISTERED");
        aCounter ++;
        airlines[aCounter] = Airline(
            {
                aId: aCounter,
                aName: _aName2,
                aAddress: payable(_aAddress2),                    
                aRegistered: true,
                aParticipant: false,
                aController: false
            }
        );
        airlinesReverse[_aAddress2] = aCounter; 
        register(_aAddress2);

        emit Registration(aCounter);
    }
    // function winningProposal() public view returns (uint winningProposal_)
    // {
    //     uint winningVoteCount = 0;
    //     for (uint p = 0; p < proposals.length; p++) {
    //         if (proposals[p].pVoteCount > winningVoteCount) {
    //             winningVoteCount = proposals[p].pVoteCount;
    //             winningProposal_ = p;
    //         }
    //     }
    // }


    /********************************************************************************************/
    /*                              SMART CONTRACT BUYING FUNCTIONS                             */
    /********************************************************************************************/
   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy() external payable {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees() external pure {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay() external pure {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    // function() 
    //                         external 
    //                         payable 
    // {
    //     fund();
    // }


    function checkAirlines(uint _aId3) public view returns(string memory name_, address address_, bool registered_, bool participant_, bool controller_) {
        return(airlines[_aId3].aName
            , airlines[_aId3].aAddress
            , airlines[_aId3].aRegistered
            , airlines[_aId3].aParticipant
            , airlines[_aId3].aController
        );
    }

    function checkCandidateAirlines() public view returns(Proposal[] memory ) {
        return proposals;
    }
}