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
        registers.add(_address);
    }

    function addController(address _address) public {
        controllers.add(_address);
    }

    function addParticipant(address _address) public {
        participants.add(_address);
    }

    function addCandidate(address _address) public {
        candidates.add(_address);
    }

    /********************************************************************************************/
    /*                                 DATA VARIABLES - AIRLINE                                 */
    /********************************************************************************************/

    address payable contractOwner;                                      // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;                                    // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    struct Airline {
        uint    aId;
        string  aName;
        address payable aAddress;
        bool    aRegistered;
        bool    aParticipant;
        bool    aController;
    }
    mapping(uint => Airline) private airlines;
    address[] multiCalls = new address[](0);
    uint M = 3;
    uint aCounter;

    /********************************************************************************************/
    /*                                  DATA VARIABLES - VOTING                                 */
    /********************************************************************************************/
    struct Voter {
        uint weight; // WEIGHT IS ACCUMULATED BY DELEGATION
        bool voted;  // IF TRUE, THAT PERSON ALREADY VOTED
        address delegate; // PERSON DELEGATED TO
        uint vote;   // INDEX OF THE VOTED PROPOSAL
    }
    // THIS IS A TYPE FOR A SINGLE PROPOSAL.
    struct Proposal {
        address pAddress;  //ADDRESS
        string pName;   // SHORT NAME
        uint pVoteCount; // NUMBER OF ACCUMULATED VOTES
    }
    Proposal[] public proposals;
    address public chairperson;
    // THIS DECLARES A STATE VARIABLE THAT STORES A `VOTER` STRUCT FOR EACH POSSIBLE ADDRESS.
    mapping(address => Voter) public voters;
    // A DYNAMICALLY-SIZED ARRAY OF `PROPOSAL` STRUCTS.

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    struct Passenger {
        uint    pId;
        address pAddress;
    }
    mapping(uint => Passenger) private passengers;
    uint participantFund = 10;

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
                aParticipant: false,
                aController: true
            });
        register(_firsAAddress);
        addController(_firsAAddress);
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Registration(uint aId);
    event Candidate(uint aId);
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
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    function registerAirline(string memory _aName, address _aAddress) external requireIsOperational() {
        require(!isRegistered(_aAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        if(aCounter < 5) {
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
            register(_aAddress);
            airlines[aCounter].aController = true;
            addController(_aAddress);
            
            emit Registration(aCounter);
        }
        else {
            require(!isCandidate(_aAddress), "ERROR: AIRLINE IS ALREADY A CANDIDATE");
            proposals.push(Proposal({
                pAddress: _aAddress,
                pName: _aName,
                pVoteCount: 0
            }));
            addCandidate(_aAddress);

            //revert("CANDIDATE ADDED AND WAITING FOR A VOTE");
            //vote(1);

            //emit Candidate(aCounter);
        }
    }

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "HAS NO RIGHT TO VOTE");
        require(!sender.voted, "ALREADY VOTED.");
        sender.voted = true;
        sender.vote = proposal;

        // IF `PROPOSAL` IS OUT OF THE RANGE OF THE ARRAY, THIS WILL THROW AUTOMATICALLY AND REVERT ALL CHANGES.
        proposals[proposal].pVoteCount += sender.weight;
    }

    function fund(uint _aId2) public payable verifyCaller(airlines[_aId2].aAddress) { //paidEnough(participantFund) //checkValue() {
        require(isRegistered(airlines[_aId2].aAddress), "ERROR: AIRLINE IS NOT REGISTERED");
        require(!isParticipant(airlines[_aId2].aAddress), "ERROR: AIRLINE IS ALREADY A PARTICIPANT");
        contractOwner.transfer(10);
        airlines[_aId2].aParticipant = true;
        addParticipant(airlines[_aId2].aAddress);
    
        emit Funding(_aId2);
    }

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