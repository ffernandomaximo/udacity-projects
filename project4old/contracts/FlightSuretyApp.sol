/*
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
/*
contract FlightSuretyApp {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
/*
    FlightSuretyData flightSuretyData;
    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

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
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/
/*    
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "CALLER IS NOT CONTRACT OWNER");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/
 /*   
    constructor(address dataContract) {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /****************************************************************************************** */
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/
    /**
    * @dev Modifier that requires the current account to have funded at least 10 eth
    */


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
/*
    function isOperational() public view returns(bool) {
        return flightSuretyData.isOperational();
    }

    function setDataContract(address dataContract) external requireContractOwner {
        flightSuretyData = FlightSuretyData(dataContract);
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
/*
    function registerAirline(string memory _name, address _address) external {
        flightSuretyData.registerAirline(_name, _address);
    }

    function checkAirline(address _address) public view returns(bool) {
        return flightSuretyData.isRegistered(_address);
    }

    function registerFlight (string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {
        flightSuretyData.registerFlight(_flight, _year, _month, _day, _hour, _minute);

    }
    
    function processFlightStatus(string memory _flight, uint256 _timestamp, uint8 _statusCode) internal {
        bytes32 _flightKey = getFlightKey(_flight, _timestamp);
//        require(flightSuretyData.flights[_flightKey].airlineAddress != address(0), "ERROR: FLIGHT IS NOT REGISTERED");

        flightSuretyData.flights[_flightKey].updatedTimestamp = _timestamp;
        flightSuretyData.flights[_flightKey].statusCode = _statusCode;

        if (_statusCode == STATUS_CODE_LATE_AIRLINE) {
            flightSuretyData.creditInsurees(_flightKey);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address _airline, string calldata _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {
        uint8 index = getRandomIndex(msg.sender);

        uint _timestamp = flightSuretyData.getDateTime(_year, _month, _day, _hour, _minute);
        
        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, _airline, _flight, _timestamp));
        oracleResponses[key].requester = msg.sender;
        oracleResponses[key].isOpen = true;

        emit OracleRequest(index, _airline, _flight, _timestamp);
    }

    // Query the status of any flight
    function viewFlightStatus(string calldata _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external view returns(uint8) {
            uint _timestamp = flightSuretyData.getDateTime(_year, _month, _day, _hour, _minute);

            bytes32 _flightKey = getFlightKey(_flight, _timestamp);
            return flightSuretyData.flights[_flightKey].statusCode;
    }

    function withdrawCredit(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public {
        uint _timestamp = flightSuretyData.getDateTime(_year, _month, _day, _hour, _minute);

        bytes32 _flightKey = getFlightKey(_flight, _timestamp);
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
            processFlightStatus(flight, timestamp, statusCode);
        }
    }

    function getFlightKey(string memory flight, uint256 timestamp) internal pure returns(bytes32){
        return keccak256(abi.encodePacked(flight, timestamp));
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
    
    function registerAirline(string memory _aName, address _aAddress) external {}
    
    function isRegistered(address _address) public view returns(bool) {}
    
    function registerFlight(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external {}

    function creditInsurees(bytes32 _flightKey) external {}

    function pay(bytes32 _flightKey) external {}
}
*/