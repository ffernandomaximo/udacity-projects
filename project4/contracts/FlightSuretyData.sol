// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Libraries
import "./DateLib.sol";

import "./RoleLib.sol";

import "./SafeMath.sol";

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;


    /********************************************************************************************/
    /*                                          DATELIB                                         */
    /********************************************************************************************/
    using DateLib for DateLib.DateTime;     

    function getDateTime(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) internal pure returns(uint) {
        uint unixDate = DateLib.toUnixTimestamp(DateLib.DateTime({
            year: _year,
            month: _month,
            day: _day,
            hour: _hour,
            minute: _minute,
            second: 0,
            ms: 0,
            weekday: 0
        })
        );
        return unixDate;
    }


    /********************************************************************************************/
    /*                                         ROLELIB                                          */
    /********************************************************************************************/
    using RoleLib for RoleLib.Role;

    RoleLib.Role private registers;
    RoleLib.Role private controllers;
    RoleLib.Role private participants;
    RoleLib.Role private candidates;            

    function register(address _address) internal {
        require(!isRegistered(_address), "ERROR: AIRLINE IS ALREADY REGISTERED");
        registers.add(_address);
    }

    function addController(address _address) internal {
        require(!isController(_address), "ERROR: AIRLINE IS ALREADY A CONTROLLER");
        controllers.add(_address);
    }

    function addParticipant(address _address) internal {
        require(!isParticipant(_address), "ERROR: AIRLINE IS ALREADY A PARTICIPANT");
        participants.add(_address);
    }
    
    function addCandidate(address _address) internal {
        require(!isCandidate(_address), "ERROR: AIRLINE IS ALREADY A CANDIDATE");
        candidates.add(_address);
    }

    function removeCandidate(address _address) internal {
        require(isCandidate(_address), "ERROR: AIRLINE IS NOT A CANDIDATE");
        candidates.remove(_address);
    }

    /********************************************************************************************/
    /*                                      AIRLINE VARIABLES                                   */
    /********************************************************************************************/
    address payable contractOwner;              // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;            // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    address[] multiCalls = new address[](0);
    uint M = 3;
    
    struct Airline {
        uint    aId;
        string  aName;
        address payable aAddress;
        bool    aRegistered;
        bool    aParticipant;
        bool    aController;
        uint    aFundAvailable;
        uint    aFundCommitted;
    }
    mapping(address => Airline) private airlines;

    uint aCounter;


    struct Flight {
        bytes32 fFlightKey;
        string fFlight;
        bool fActive;
        uint8 fStatusCode;
        uint256 fUpdatedTimestamp;        
        address aAddress;
    }
    mapping(bytes32 => Flight) private flights;
    mapping(uint => bytes32) private flightsReverse;
    uint fCounter;

    /********************************************************************************************/
    /*                             CANDIDATE AIRLINE VARIABLES                                  */
    /********************************************************************************************/
    struct Proposal {
        address pAddress;                       // ADDRESS
        string  pName;                           // SHORT NAME
        uint    pVoteCount;                        // NUMBER OF ACCUMULATED VOTES
        bool    pActive;                           // PROPOSAL STATUS
    }
    Proposal[] private proposals;
    mapping(address => address[]) private voters;


    /********************************************************************************************/
    /*                                    PASSENGER VARIABLES                                   */
    /********************************************************************************************/
    mapping(address => uint) private passengers;


    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    struct Insurance {
        bytes32 fFlightKey;
        address payable psAddress;
        uint iAmountPaid;
        bool iActive;
    }
    mapping(bytes32 => Insurance) private insurances;
    mapping(uint => bytes32) private insurancesReverse;
    
    function getInsuranceKey(bytes32 _fFlightKey) private view returns(bytes32) {
        bytes32 _addressToBytes32 = bytes32(uint256(uint160(msg.sender)) << 96);
        return keccak256(abi.encodePacked(_addressToBytes32, _fFlightKey));
    }
    uint iCounter;

    /********************************************************************************************/
    /*                                       CONSTRUCTOR DEFINITION                             */
    /********************************************************************************************/    
    /* The deploying account becomes contractOwner */
    constructor() {
        contractOwner = payable(msg.sender);
        aCounter = 1;
        address _firsAAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
        string memory _firstName = "Air New Zealand";
        airlines[_firsAAddress] = Airline(
            {
                aId: aCounter,
                aName: _firstName,
                aAddress: payable(_firsAAddress),
                aRegistered: true,
                aParticipant: false,
                aController: true,
                aFundAvailable: 0,
                aFundCommitted: 0
            });
        register(_firsAAddress);
        addController(_firsAAddress);
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
  
    modifier checkParticipantValue() {
        require(msg.value == 10 ether, "AIRLINE MUST TRANSFER EXACTLY 10 ETHERS");
        _;
    }

    modifier checkPassengerValue() {
        require(msg.value >= 1 gwei && msg.value <= 1 ether, "CALLER MUST SPEND BETWEEN 1 GWEI AND 1 ETHER");
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

    function isOperational() private view returns(bool) {
        return operational;
    }
    
    function isRegistered(address _address) private view returns(bool) {
        return registers.has(_address);
    }

    function isController(address _address) private view returns(bool) {
        return controllers.has(_address);
    }

    function isParticipant(address _address) private view returns(bool) {
        return participants.has(_address); 
    }

    function isCandidate(address _address) private view returns(bool) {
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
        
        require(!isDuplicate, "ERROR: CALLER HAS ALREADY CALLED THIS FUNCTION");

        multiCalls.push(msg.sender);
        if (multiCalls.length >= M) {
            operational = mode;
            multiCalls = new address[](0);
        }
    }


    /********************************************************************************************/
    /*                       SMART CONTRACT REGISTER AIRLINES FUNCTIONS                         */
    /********************************************************************************************/
    function candidateAirline(string memory _cName, address _cAddress) internal requireIsOperational() {
        require(!isRegistered(_cAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        require(!isCandidate(_cAddress), "ERROR: AIRLINE IS ALREADY A CANDIDATE");

        proposals.push(Proposal({
            pAddress: _cAddress,
            pName: _cName,
            pVoteCount: 0,
            pActive: true
        }));
        addCandidate(_cAddress);
     
        emit Candidate(_cName);
    }
    
    function registerAirline(string memory _aName, address _aAddress) external requireIsOperational() {
        require(!isRegistered(_aAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        if(aCounter < 4) {
            require(msg.sender == contractOwner || isController(msg.sender), "ERROR: CALLER IS NOT CONTROLLER");

            aCounter ++;
            airlines[_aAddress] = Airline(
                {
                    aId: aCounter,
                    aName: _aName,
                    aAddress: payable(_aAddress),                    
                    aRegistered: true,
                    aParticipant: false,
                    aController: false,
                    aFundAvailable: 0,
                    aFundCommitted: 0
                }
            );
            register(_aAddress);
            airlines[_aAddress].aController = true;
            addController(_aAddress);
            
            //emit Registration(aCounter);

        }
        else {
            candidateAirline(_aName, _aAddress);
        }
    }

    function registerAirlineVote(string memory _aName2, address _aAddress2) internal requireIsOperational() {
        require(!isRegistered(_aAddress2), "ERROR: AIRLINE IS ALREADY REGISTERED");

        aCounter ++;
        airlines[_aAddress2] = Airline(
            {
                aId: aCounter,
                aName: _aName2,
                aAddress: payable(_aAddress2),                    
                aRegistered: true,
                aParticipant: false,
                aController: false,
                aFundAvailable: 0,
                aFundCommitted: 0
            }
        );
        register(_aAddress2);
        removeCandidate(_aAddress2);

        emit Registration(aCounter);
    }


    /********************************************************************************************/
    /*                          SMART CONTRACT PARTICIPANT FUNCTIONS                            */
    /********************************************************************************************/
    function fund() public payable paidEnough(10 ether) checkParticipantValue() requireIsOperational() {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(!isParticipant(msg.sender), "ERROR: CALLER IS ALREADY A PARTICIPANT");

        contractOwner.transfer(msg.value);

        airlines[msg.sender].aParticipant = true;
        airlines[msg.sender].aFundAvailable = msg.value;
        addParticipant(msg.sender);
    
        //emit Funding(msg.sender);
    }


    /********************************************************************************************/
    /*                              SMART CONTRACT VOTING FUNCTIONS                             */
    /********************************************************************************************/
    function vote(string memory _vName, address _vAddress) public requireIsOperational() {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(!isRegistered(_vAddress), "ERROR: AIRLINE VOTED IS ALREADY REGISTERED");
        require(isCandidate(_vAddress), "ERROR: AIRLINE VOTED IS NOT A CANDIDATE");

        bool found = false;
        uint result = 0;
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
                result = (proposals[p].pVoteCount * 100) / aCounter;
                if(result >= 50){
                   registerAirlineVote(_vName, _vAddress);
                   proposals[p].pActive = false;
                }
                break;
            }
        }
    }

    /********************************************************************************************/
    /*                          SMART CONTRACT REGISTER FLIGHT FUNCTIONS                        */
    /********************************************************************************************/
    function getFlightKey(//address _airline, 
        string memory _flight, uint _timestamp) pure internal returns(bytes32){
        return keccak256(abi.encodePacked(//_airline, 
            _flight, _timestamp));
    
    }
    
    function registerFlight (string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {
        require(isParticipant(msg.sender), "ERROR: CALLER IS NOT A PARTICIPANT");
        
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        require(SafeMath.sub(_timestamp, block.timestamp) > 172800, "ERROR: FLIGHT TIME MUST BE AT LEAST 48 HOURS THAN NOW");
         
        bytes32 flightKey = getFlightKey(//msg.sender, 
            _flight, _timestamp);
        
        require(flights[flightKey].aAddress == address(0), "ERROR: FLIGHT ALREADY REGISTERED");
        
        flights[flightKey] = Flight({
            fFlightKey: flightKey,
            fFlight: _flight,
            fActive: true,
            fStatusCode: 0,
            fUpdatedTimestamp: getDateTime(_year, _month, _day, _hour, _minute),
            aAddress: msg.sender
        });
        
        fCounter++;
        flightsReverse[fCounter] = flightKey;
    
    }



    /********************************************************************************************/
    /*                              SMART CONTRACT BUYING FUNCTIONS                             */
    /********************************************************************************************/
    //function buy(address airline, string memory flight, uint256 timestamp) external payable checkPassengerValue() requireIsOperational() {
    function buy(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public payable checkPassengerValue() requireIsOperational() {
        require(!isRegistered(msg.sender) && msg.sender != contractOwner, "ERROR: CALLER IS NOT ALLOWED TO BUY INSURANCE");
        
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        
        bytes32 flightKey = getFlightKey(//msg.sender, 
            _flight, _timestamp);
        
        require(keccak256(abi.encodePacked(flights[flightKey].fFlight)) == keccak256(abi.encodePacked(_flight)), "ERROR: FLIGHT NOT FOUND");
        
        address _aAddress = flights[flightKey].aAddress;

        bytes32 _insuranceKey = getInsuranceKey(flightKey);
        
        require(insurances[_insuranceKey].fFlightKey != flightKey, "ERROR: PASSENGER ALREADY BOUGHT THIS FLIGHT INSURANCE");
        contractOwner.transfer(msg.value);
        iCounter ++;
        insurances[_insuranceKey] = Insurance(
            {
                fFlightKey: flightKey,
                psAddress: payable(msg.sender),
                iAmountPaid: msg.value,
                iActive: true
            }
        );
        insurancesReverse[iCounter] = _insuranceKey;

        airlines[_aAddress].aFundAvailable = SafeMath.add(airlines[_aAddress].aFundAvailable, msg.value);
        airlines[_aAddress].aFundCommitted = SafeMath.div(SafeMath.mul(msg.value, 15), 10);
        
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 _fFlightKey) external {
        address _aAddress = flights[_fFlightKey].aAddress;
        uint _amountPaid = insurances[_fFlightKey].iAmountPaid;
        uint _amountToCredit = SafeMath.div(SafeMath.mul(_amountPaid, 15), 10);

        uint _fundAvailable = airlines[_aAddress].aFundAvailable;
        uint _fundCommitted = airlines[_aAddress].aFundCommitted;
        airlines[_aAddress].aFundAvailable = SafeMath.sub(_fundAvailable, _amountToCredit);
        airlines[_aAddress].aFundCommitted = SafeMath.sub(_fundCommitted, _amountToCredit);
        

    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay() public payable requireIsOperational() {
        payable(msg.sender).transfer(passengers[msg.sender]);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   

    // function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
    //     return keccak256(abi.encodePacked(airline, flight, timestamp));
    // }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() external payable {
    }
    
    receive() external payable {
    }


    /********************************************************************************************/
    /*                               SMART CONTRACT CHECK FUNCTIONS                             */
    /********************************************************************************************/
    function checkAirlines(address _aAddress) public view returns(string memory name_, address address_, 
        bool registered_, bool participant_, bool controller_, 
        uint fundavailable_, uint fundcommitted_) {
        
        return(airlines[_aAddress].aName
            , airlines[_aAddress].aAddress
            , airlines[_aAddress].aRegistered
            , airlines[_aAddress].aParticipant
            , airlines[_aAddress].aController
            , airlines[_aAddress].aFundAvailable
            , airlines[_aAddress].aFundCommitted
        );
    
    }

    function checkFlights(uint _fFlightId) public view returns(bytes32 key_, string memory flight_, bool active_, uint8 status_, uint256 timestamp_, address address_) {
        bytes32 _fFlightKey = flightsReverse[_fFlightId];
        return(flights[_fFlightKey].fFlightKey
            , flights[_fFlightKey].fFlight
            , flights[_fFlightKey].fActive
            , flights[_fFlightKey].fStatusCode
            , flights[_fFlightKey].fUpdatedTimestamp        
            , flights[_fFlightKey].aAddress
        );
    
    }

    function checkCandidateAirlines() public view returns(Proposal[] memory ) {
        return proposals;
    }

    function checkInsurances(uint _iId) public view returns(bytes32 flightKey_, address passengerAddress_, uint amountPaid_) {
        bytes32 _insuranceKey = insurancesReverse[_iId];
        return(insurances[_insuranceKey].fFlightKey
            , insurances[_insuranceKey].psAddress
            , insurances[_insuranceKey].iAmountPaid
        );
    }
}