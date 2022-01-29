// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DateLib.sol";
import "./RoleLib.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyApp {
    using SafeMath for uint256;

    bool private operational = true;            // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    address[] multiCalls = new address[](0);
    uint M = 3;


    /********************************************************************************************/
    /*                                          DATELIB                                         */
    /********************************************************************************************/
    using DateLib for DateLib.DateTime;         //LIBRARY USED TO CONVERT HUMAN DATE TIME TO EPOCH TIMESTAMP

    function getDateTime(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public pure returns(uint) {
        uint unixDate = DateLib.toUnixTimestamp(DateLib.DateTime({
            year: _year,
            month: _month,
            day: _day,
            hour: _hour,
            minute: _minute,
            second: 0,
            ms: 0,
            weekday: 0
        }));
        
        return unixDate;
    }

    
    /********************************************************************************************/
    /*                                         ROLELIB                                          */
    /********************************************************************************************/
    using RoleLib for RoleLib.Role;             //LIBRARY USED TO CLASSIFY AIRLINES INTO DIFFERENT ROLES

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
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    FlightSuretyData flightSuretyData;
    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    uint aCounter = 1;

    // // flights data
    // struct Flight {
    //     bool isRegistered;
    //     string flightCode;
    //     string destination;
    //     uint8 statusCode;
    //     uint256 updatedTimestamp;
    //     address airline;
    // }
    // mapping(bytes32 => Flight) private flights;
    // mapping(address => address[]) private airlineVoters;


    /********************************************************************************************/
    /*                             CANDIDATE AIRLINE VARIABLES                                  */
    /********************************************************************************************/
    struct Proposal {
        address         proposedAddress;
        string          proposedName;
        uint            voteCount;
        bool            active;
    }
    Proposal[] private proposals;
    mapping(address => address[]) voters;


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/
    modifier requireIsOperational() {
        require(isOperational(), "CONTRACT IS CURRENTLY NOT OPERATIONAL");
        _;
    }
    
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "CALLER IS NOT CONTRACT OWNER");
        _;
    }

    modifier requireController() {
        require(msg.sender == contractOwner || controllers.has(msg.sender), "CALLER IS NOT A CONTROLLER");
        _;
    }


    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/
    constructor(address dataContract) {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
        address _firstAirlineAddress = flightSuretyData.getFirstAirlineAddress();
        register(_firstAirlineAddress);
        addController(_firstAirlineAddress);
    }

    // function setFirstController() external requireContractOwner() {
    //     address _firstAirlineAddress = flightSuretyData.getFirstAirlineAddress();
    //     register(_firstAirlineAddress);
    //     addController(_firstAirlineAddress);
    // }


    /********************************************************************************************/
    /*                                  OPERATIONAL STATUS CONTROL                              */
    /********************************************************************************************/
    function setOperatingStatus(bool mode) external requireController() {
        require(mode != operational, "NEW MODE MUST BE DIFERENT FROM THE EXISITNG");

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
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function isOperational() public view returns(bool) {
        return flightSuretyData.isOperational();
    }

    function setDataContract(address dataContract) external requireContractOwner {
        flightSuretyData = FlightSuretyData(dataContract);
    }

    function isController(address _address) public view returns(bool) {
        //return controllers.has(_address);
        return (_address == contractOwner || controllers.has(_address));
    }

    function isRegistered(address _address) public view returns(bool) {
        return registers.has(_address);
    }

    function isParticipant(address _address) public view returns(bool) {
        return participants.has(_address); 
    }

    function isCandidate(address _address) public view returns(bool) {
        return candidates.has(_address);
    }


    /********************************************************************************************/
    /*                                        AIRLINE FUNCTIONS                                 */
    /********************************************************************************************/
    function registerAirline(string memory _name, address _address) public requireIsOperational() {
        require(!isRegistered(_address), "ERROR: AIRLINE IS ALREADY REGISTERED");
        
        if(aCounter < 4) {
            require(msg.sender == contractOwner || isController(msg.sender), "ERROR: CALLER IS NOT CONTROLLER");
            
            aCounter ++;
            flightSuretyData.registerAirline(_name, _address, aCounter, true);
            
            register(_address);
            addController(_address);
        
        } else {
            candidateAirline(_name, _address);

            addCandidate(_address);
        }
    }

    function candidateAirline(string memory _name, address _address) public requireIsOperational() {
        require(!isRegistered(_address), "ERROR: AIRLINE IS ALREADY REGISTERED");
        require(!isCandidate(_address), "ERROR: AIRLINE IS ALREADY A CANDIDATE");
        
        proposals.push(Proposal({
            proposedAddress: _address,
            proposedName: _name,
            voteCount: 0,
            active: true
            })
        );
    }

    function vote(string memory _name, address _address) public requireIsOperational() {
        require(isRegistered(msg.sender), "ERROR: VOTER IS NOT REGISTERED");
        require(!isRegistered(_address), "ERROR: AIRLINE VOTED IS ALREADY REGISTERED");
        require(isCandidate(_address), "ERROR: AIRLINE VOTED IS NOT A CANDIDATE");
        
        bool found = false;
        uint result = 0;
        for (uint v = 0; v < voters[msg.sender].length; v++) {
            if(voters[msg.sender][v] == _address){
                found = true;
                revert("ERROR: CALLER ALREADY VOTED FOR THIS AIRLINE");
            }
        }
        if(!found){
            voters[msg.sender].push(_address);
        }
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].proposedAddress == _address) {
                proposals[p].voteCount += 1;
                result = (proposals[p].voteCount * 100) / aCounter;
                if(result >= 50){
                    aCounter ++;
                    flightSuretyData.registerAirline(_name, _address, aCounter, false);

                    register(_address);
                    removeCandidate(_address);
                    proposals[p].active = false;
                }
                break;
            }
        }
    }

    function fund() external payable requireIsOperational() {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(!isParticipant(msg.sender), "ERROR: CALLER IS ALREADY A PARTICIPANT");

        flightSuretyData.fund{value: msg.value}(msg.sender);

        addParticipant(msg.sender);
    }

    function checkAirlines(address _address) external view 
    returns(string memory name_, address address_, bool registered_, bool participant_, bool controller_, uint fundavailable_, uint fundcommitted_) {   
        return flightSuretyData.checkAirlines(_address);
    }

    function checkCandidateAirlines() public view returns(Proposal[] memory ) {
        return proposals;
    }


    /********************************************************************************************/
    /*                                        FLIGHT FUNCTIONS                                  */
    /********************************************************************************************/
    function registerFlight (string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {
        require(isParticipant(msg.sender), "ERROR: CALLER IS NOT A PARTICIPANT");
        
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        
        require(_timestamp > block.timestamp + 172800, "ERROR: FLIGHT TIME MUST BE AT LEAST 48 HOURS THAN NOW");
         
        bytes32 _flightKey = getFlightKey(msg.sender, _flight, _timestamp);
        
        require(!flightSuretyData.checkFlight(_flightKey), "ERROR: FLIGHT ALREADY REGISTERED");

        flightSuretyData.registerFlight(_flightKey, _flight, _timestamp);

    }

    function checkFlights(uint _flightId) external view
    returns(bytes32 key_, string memory flight_, bool active_, uint8 status_, uint256 timestamp_, address address_) {
        return flightSuretyData.checkFlights(_flightId);
    }

    function processFlightStatus(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute, uint8 _statusCode) internal {
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        bytes32 _flightKey = getFlightKey(msg.sender, _flight, _timestamp);
        
        require(flightSuretyData.checkFlight(_flightKey), "ERROR: FLIGHT IS NOT REGISTERED");

        flightSuretyData.updateFlightTimestamp(_flightKey, _timestamp);
        flightSuretyData.updateFlightStatus(_flightKey, _statusCode);

        if (_statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightSuretyData.creditInsurees(_flightKey);
        }
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address _airline, string calldata _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {
        uint8 index = getRandomIndex(msg.sender);

        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, _airline, _flight, _timestamp));
        oracleResponses[key].requester = msg.sender;
        oracleResponses[key].isOpen = true;

        emit OracleRequest(index, _airline, _flight, _timestamp);
    }

    // Query the status of any flight
    function viewFlightStatus(string calldata _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external view returns(uint8) {
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);

        bytes32 _flightKey = getFlightKey(msg.sender, _flight, _timestamp);
        return flightSuretyData.getFlightStatus(_flightKey);
    }

    function withdrawCredit(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public {
        //uint _timestamp = flightSuretyData.getDateTime(_year, _month, _day, _hour, _minute);
        uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);

        bytes32 _flightKey = getFlightKey(msg.sender, _flight, _timestamp);
        flightSuretyData.pay(_flightKey);
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "ERROR: REGISTRATION FEE IS REQUIRED");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes() external view returns(uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "ERROR: ORACLE NOT REGISTERED");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, string calldata flight, uint256 timestamp, uint8 statusCode)
    external {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "ERROR: INDEX NOT MATCHING ORACLE REQUEST");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "ERROR: FLIGHT/TIMESTAMP NOT MATCHING ORACLE REQUEST");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            //processFlightStatus(flight, timestamp, statusCode);
        }
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address _account) internal returns(uint8[3] memory) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(_account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(_account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(_account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address _account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), _account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

contract FlightSuretyData {


    function isOperational() external view returns(bool) {}

    function getFirstAirlineAddress() external view returns(address){}
    
    function registerAirline(string memory _name, address _address, uint _aCounter, bool _controller) external {}

    function candidateAirline(string memory _name, address _address) external {}

    function fund(address _address) external payable {}
    
    function checkAirlines(address _airlineAddress) external view 
    returns(string memory name_, address address_, bool registered_, bool participant_, bool controller_, uint fundavailable_, uint fundcommitted_) {}

    function registerFlight(bytes32 _flightKey, string memory _flight, uint _timestamp) external {}

    function checkFlight(bytes32 _flightKey) external view returns(bool) {}

    function checkFlights(uint _flightId) external view
    returns(bytes32 key_, string memory flight_, bool active_, uint8 status_, uint256 timestamp_, address address_) {}

    function updateFlightTimestamp(bytes32 _flightKey, uint256 _timestamp) external {}
    
    function updateFlightStatus(bytes32 _flightKey, uint8 _statusCode) external {}

    function getFlightStatus(bytes32 _flightKey) external view returns(uint8) {}

    function creditInsurees(bytes32 _flightKey) external {}

    function pay(bytes32 _flightKey) external {}

    //function getDateTime(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public pure returns(uint) {}
}
