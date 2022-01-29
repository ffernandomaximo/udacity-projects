// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Libraries
import "./DateLib.sol";

import "./accesscontrol/RoleLib.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {

    address payable contractOwner;              // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;            // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    address[] multiCalls = new address[](0);
    uint M = 3;

    mapping(address => bool) AuthorizedCallers; //AUTHORIZED CALLERS 
    

    /********************************************************************************************/
    /*                                         SAFEMATH                                         */
    /********************************************************************************************/
    using SafeMath for uint256;                 //LIBRARY USED TO EXECUTE MATH OPERATIONS         


    /********************************************************************************************/
    /*                                          DATELIB                                         */
    /********************************************************************************************/
    // using DateLib for DateLib.DateTime;         //LIBRARY USED TO CONVERT HUMAN DATE TIME TO EPOCH TIMESTAMP

    // function getDateTime(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public pure returns(uint) {
    //     uint unixDate = DateLib.toUnixTimestamp(DateLib.DateTime({
    //         year: _year,
    //         month: _month,
    //         day: _day,
    //         hour: _hour,
    //         minute: _minute,
    //         second: 0,
    //         ms: 0,
    //         weekday: 0
    //     })
    //     );
    //     return unixDate;
    // }


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
    /*                                      AIRLINE VARIABLES                                   */
    /********************************************************************************************/
    struct Airline {
        uint            airlineId;
        string          airlineName;
        address payable airlineAddress;
        bool            registered;
        bool            participant;
        bool            controller;
        uint            fundAvailable;
        uint            fundCommitted;
    }
    mapping(address => Airline) public airlines;
    uint aCounter;


    /********************************************************************************************/
    /*                                      FLIGHT VARIABLES                                    */
    /********************************************************************************************/
    struct Flight {
        bytes32         flightKey;
        string          flight;
        bool            active;
        uint8           statusCode;
        uint256         updatedTimestamp;
        address         airlineAddress;
    }
    mapping(bytes32 => Flight) public flights;
    mapping(uint => bytes32) private flightsReverse;
    uint fCounter;


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
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/
    struct Insurance {
        bytes32         insuranceKey;
        bytes32         flightKey;
        address payable passengerAddress;
        uint            amountPaid;
        uint            amountAvailable;
        bool            claimable;
        bool            active;
    }
    mapping(bytes32 => Insurance) insurances;
    mapping(uint => bytes32) private insurancesReverse;
    uint iCounter;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event Registration(address);
    event Candidate(address);
    event Funding(address);
    event Acquisition(address);
    event Payment(address);


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
        require(msg.sender == contractOwner || controllers.has(msg.sender), "CALLER IS NOT AN AUTHORIZED CONTRACT");
        _;
    }

    modifier requireAuthorizedCaller(){
        require(AuthorizedCallers[msg.sender] == true, "Caller is not authorized");
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
    /*                                       CONSTRUCTOR DEFINITION                             */
    /********************************************************************************************/    
    /* The deploying account becomes contractOwner */
    constructor() {
        contractOwner = payable(msg.sender);
        aCounter = 1;
        address _firsairlineAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
        string memory _firstName = "Air New Zealand";
        airlines[_firsairlineAddress] = Airline(
            {
                airlineId: aCounter,
                airlineName: _firstName,
                airlineAddress: payable(_firsairlineAddress),
                registered: true,
                participant: false,
                controller: true,
                fundAvailable: 0,
                fundCommitted: 0
            });
        register(_firsairlineAddress);
        addController(_firsairlineAddress);
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
        return registers.has(_address);
    }

    function isController(address _address) public view returns(bool) {
        return controllers.has(_address);
    }

    function isParticipant(address _address) public view returns(bool) {
        return participants.has(_address); 
    }

    function isCandidate(address _address) public view returns(bool) {
        return candidates.has(_address);
    }

    function authorizeCaller(address _caller) public requireContractOwner {
        AuthorizedCallers[_caller] = true;
    }

    function isAuthorized(address _caller) public view returns(bool) {
        return AuthorizedCallers[_caller];
    }

    function deAuthorizeCaller(address _caller) public requireContractOwner {
        AuthorizedCallers[_caller] = false;
    }


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
    /*                       SMART CONTRACT REGISTER AIRLINES FUNCTIONS                         */
    /********************************************************************************************/
    function candidateAirline(string memory _cName, address _cAddress) internal requireIsOperational() {
        require(!isRegistered(_cAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        require(!isCandidate(_cAddress), "ERROR: AIRLINE IS ALREADY A CANDIDATE");

        proposals.push(Proposal({
            proposedAddress: _cAddress,
            proposedName: _cName,
            voteCount: 0,
            active: true
        }));
        addCandidate(_cAddress);
     
        emit Candidate(_cAddress);
    }
    
    function registerAirline(string memory _airlineName, address _airlineAddress) external requireAuthorizedCaller() requireIsOperational() {
        require(!isRegistered(_airlineAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        if(aCounter < 4) {
            require(msg.sender == contractOwner || isController(msg.sender), "ERROR: CALLER IS NOT CONTROLLER");

            aCounter ++;
            airlines[_airlineAddress] = Airline(
                {
                    airlineId: aCounter,
                    airlineName: _airlineName,
                    airlineAddress: payable(_airlineAddress),                    
                    registered: true,
                    participant: false,
                    controller: false,
                    fundAvailable: 0,
                    fundCommitted: 0
                }
            );
            register(_airlineAddress);
            airlines[_airlineAddress].controller = true;
            addController(_airlineAddress);
            
            emit Registration(_airlineAddress);

        }
        else {
            candidateAirline(_airlineName, _airlineAddress);
        }
    }

    function registerAirlineByVote(string memory _airlineName2, address _airlineAddress2) internal requireIsOperational() {
        require(!isRegistered(_airlineAddress2), "ERROR: AIRLINE IS ALREADY REGISTERED");

        aCounter ++;
        airlines[_airlineAddress2] = Airline(
            {
                airlineId: aCounter,
                airlineName: _airlineName2,
                airlineAddress: payable(_airlineAddress2),                    
                registered: true,
                participant: false,
                controller: false,
                fundAvailable: 0,
                fundCommitted: 0
            }
        );
        register(_airlineAddress2);
        removeCandidate(_airlineAddress2);

        emit Registration(_airlineAddress2);
    }


    /********************************************************************************************/
    /*                          SMART CONTRACT PARTICIPANT FUNCTIONS                            */
    /********************************************************************************************/
    function fund() public payable paidEnough(10 ether) checkParticipantValue() requireAuthorizedCaller() requireIsOperational() {
        require(isRegistered(msg.sender), "ERROR: CALLER IS NOT REGISTERED");
        require(!isParticipant(msg.sender), "ERROR: CALLER IS ALREADY A PARTICIPANT");

        contractOwner.transfer(msg.value);

        airlines[msg.sender].participant = true;
        airlines[msg.sender].fundAvailable = msg.value;
        addParticipant(msg.sender);
    
        //emit Funding(msg.sender);
    }


    /********************************************************************************************/
    /*                              SMART CONTRACT VOTING FUNCTIONS                             */
    /********************************************************************************************/
    function vote(string memory _vName, address _vAddress) external requireAuthorizedCaller() requireIsOperational() {
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
            if (proposals[p].proposedAddress == _vAddress) {
                proposals[p].voteCount += 1;
                result = (proposals[p].voteCount * 100) / aCounter;
                if(result >= 50){
                   registerAirlineByVote(_vName, _vAddress);
                   proposals[p].active = false;
                }
                break;
            }
        }
    }


    /********************************************************************************************/
    /*                                  KEYS GENEARTOR FUNCTIONS                                */
    /********************************************************************************************/
    function getFlightKey(//address _airline, 
        string memory _flight, uint _timestamp) pure internal returns(bytes32){
        return keccak256(abi.encodePacked(//_airline, 
            _flight, _timestamp));
    
    }
    
    function getInsuranceKey(address _passengerAddress, bytes32 _flightKey) pure internal returns(bytes32) {
        bytes32 _addressToBytes32 = bytes32(uint256(uint160(_passengerAddress)) << 96);
        return keccak256(abi.encodePacked(_addressToBytes32, _flightKey));
    }


    /********************************************************************************************/
    /*                          SMART CONTRACT REGISTER FLIGHT FUNCTIONS                        */
    /********************************************************************************************/
    //function registerFlight (string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) external requireAuthorizedCaller() requireIsOperational() {
    function registerFlight (string memory _flight, uint _timestamp) external requireAuthorizedCaller() requireIsOperational() {    
        require(isParticipant(msg.sender), "ERROR: CALLER IS NOT A PARTICIPANT");
        
        //uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        require(_timestamp > block.timestamp + 172800, "ERROR: FLIGHT TIME MUST BE AT LEAST 48 HOURS THAN NOW");
         
        bytes32 flightKey = getFlightKey(//msg.sender, 
            _flight, _timestamp);
        
        require(flights[flightKey].airlineAddress == address(0), "ERROR: FLIGHT ALREADY REGISTERED");
        
        flights[flightKey] = Flight({
            flightKey: flightKey,
            flight: _flight,
            active: true,
            statusCode: 0,
            updatedTimestamp: _timestamp,
            airlineAddress: msg.sender
        });
        
        fCounter++;
        flightsReverse[fCounter] = flightKey;
    
    }

    function checkFlight(bytes32 _flightKey) external view requireAuthorizedCaller() requireIsOperational() returns(bool) {
        bool _isRegistered;
        if (flights[_flightKey].airlineAddress == address(0)) {
            _isRegistered = false;
        }
        else {
            _isRegistered = true;
        }

        return _isRegistered;
    }

    function updateFlightTimestamp(bytes32 _flightKey, uint256 _timestamp) external requireAuthorizedCaller() requireIsOperational()  {
        flights[_flightKey].updatedTimestamp = _timestamp;
    }

    function updateFlightStatus(bytes32 _flightKey, uint8 _statusCode) external requireAuthorizedCaller() requireIsOperational()  {
        flights[_flightKey].statusCode = _statusCode;
    }

    function getFlightStatus(bytes32 _flightKey) external view requireAuthorizedCaller() requireIsOperational() returns(uint8) {
        return flights[_flightKey].statusCode;
    }



    /********************************************************************************************/
    /*                              SMART CONTRACT BUYING FUNCTIONS                             */
    /********************************************************************************************/
    //function buy(string memory _flight, uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute) public payable checkPassengerValue() requireAuthorizedCaller() requireIsOperational() {
    function buy(string memory _flight, uint _timestamp) public payable checkPassengerValue() requireAuthorizedCaller() requireIsOperational() {
        require(!isRegistered(msg.sender) && msg.sender != contractOwner, "ERROR: CALLER IS NOT ALLOWED TO BUY INSURANCE");
        
        //uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        
        bytes32 flightKey = getFlightKey(//msg.sender, 
            _flight, _timestamp);
        
        require(keccak256(abi.encodePacked(flights[flightKey].flight)) == keccak256(abi.encodePacked(_flight)), "ERROR: FLIGHT NOT FOUND");
        
        address _airlineAddress = flights[flightKey].airlineAddress;

        bytes32 _insuranceKey = getInsuranceKey(msg.sender, flightKey);
        
        require(insurances[_insuranceKey].flightKey != flightKey, "ERROR: PASSENGER ALREADY BOUGHT THIS FLIGHT INSURANCE");
        contractOwner.transfer(msg.value);
        iCounter ++;
        insurances[_insuranceKey] = Insurance(
            {
                insuranceKey: _insuranceKey,
                flightKey: flightKey,
                passengerAddress: payable(msg.sender),
                amountPaid: msg.value,
                amountAvailable: 0,
                claimable: false,
                active: true
            }
        );
        insurancesReverse[iCounter] = _insuranceKey;

        airlines[_airlineAddress].fundAvailable = SafeMath.add(airlines[_airlineAddress].fundAvailable, msg.value);
        airlines[_airlineAddress].fundCommitted = SafeMath.div(SafeMath.mul(msg.value, 15), 10);
        
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 _flightKey) external requireAuthorizedCaller() requireIsOperational() {
        bytes32 _insuranceKey = getInsuranceKey(msg.sender, _flightKey);
        require(insurances[_insuranceKey].flightKey == _flightKey, "ERROR: INSURANCE NOT FOUND");
        require(insurances[_insuranceKey].claimable, "ERROR: NOTHING TO CLAIM");

        address _airlineAddress = flights[_flightKey].airlineAddress;
        uint _amountPaid = insurances[_insuranceKey].amountPaid;
        uint _amountToCredit = SafeMath.div(SafeMath.mul(_amountPaid, 15), 10);

        uint _fundAvailable = airlines[_airlineAddress].fundAvailable;
        uint _fundCommitted = airlines[_airlineAddress].fundCommitted;

        insurances[_insuranceKey].amountAvailable = _amountToCredit;

        airlines[_airlineAddress].fundAvailable = SafeMath.sub(_fundAvailable, _amountToCredit);
        airlines[_airlineAddress].fundCommitted = SafeMath.sub(_fundCommitted, _amountToCredit);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(bytes32 _flightKey) public payable requireIsOperational() {
        bytes32 _insuranceKey = getInsuranceKey(msg.sender, _flightKey);
        payable(msg.sender).transfer(insurances[_insuranceKey].amountAvailable);
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
    function checkAirlines(address _airlineAddress) 
        public view requireAuthorizedCaller() requireIsOperational()
        returns(string memory name_, address address_, bool registered_, bool participant_, bool controller_, uint fundavailable_, uint fundcommitted_)  
    {
        
        return(airlines[_airlineAddress].airlineName
            , airlines[_airlineAddress].airlineAddress
            , airlines[_airlineAddress].registered
            , airlines[_airlineAddress].participant
            , airlines[_airlineAddress].controller
            , airlines[_airlineAddress].fundAvailable
            , airlines[_airlineAddress].fundCommitted
        );
    
    }

    function checkFlights(uint _flightId) 
        public view requireAuthorizedCaller() requireIsOperational()
        returns(bytes32 key_, string memory flight_, bool active_, uint8 status_, uint256 timestamp_, address address_) 
    {
        bytes32 _flightKey = flightsReverse[_flightId];
        return(flights[_flightKey].flightKey
            , flights[_flightKey].flight
            , flights[_flightKey].active
            , flights[_flightKey].statusCode
            , flights[_flightKey].updatedTimestamp        
            , flights[_flightKey].airlineAddress
        );
    
    }

    function checkCandidateAirlines() public view requireAuthorizedCaller() requireIsOperational() returns(Proposal[] memory ) {
        return proposals;
    }

    function checkInsurances(uint _iId) public view requireAuthorizedCaller() requireIsOperational()
        returns(bytes32 flightKey_, address passengerAddress_, uint amountPaid_, uint amountAvailable_, bool claimable_, bool active_) 
    {
        bytes32 _insuranceKey = insurancesReverse[_iId];
        return(insurances[_insuranceKey].flightKey
            , insurances[_insuranceKey].passengerAddress
            , insurances[_insuranceKey].amountPaid
            , insurances[_insuranceKey].amountAvailable
            , insurances[_insuranceKey].claimable
            , insurances[_insuranceKey].active
        );
    }
}