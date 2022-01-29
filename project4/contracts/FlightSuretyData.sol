// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {

    address payable contractOwner;              // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;            // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE

    mapping(address => bool) AuthorizedCallers; //AUTHORIZED CALLERS 
    
    using SafeMath for uint256;                 //LIBRARY USED TO EXECUTE MATH OPERATIONS


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

    address _firstAirlineAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
    string _firstName = "Air New Zealand";

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
    /*                                  INSURANCE VARIABLES                                     */
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
        airlines[_firstAirlineAddress] = Airline(
            {
                airlineId: 0,
                airlineName: _firstName,
                airlineAddress: payable(_firstAirlineAddress),
                registered: true,
                participant: false,
                controller: true,
                fundAvailable: 0,
                fundCommitted: 0
            });

    }

    function getFirstAirlineAddress() external view returns(address){
        return _firstAirlineAddress;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    function kill() public requireContractOwner() {
        if (msg.sender == contractOwner) {
            selfdestruct(contractOwner);
        }
    }

    function isOperational() external view returns(bool) {
        return operational;
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
    /*                       SMART CONTRACT REGISTER AIRLINES FUNCTIONS                         */
    /********************************************************************************************/
    function registerAirline(string memory _name, address _address, uint _aCounter, bool _controller) external requireAuthorizedCaller() requireIsOperational() {
        airlines[_address] = Airline(
            {
                airlineId: _aCounter,
                airlineName: _name,
                airlineAddress: payable(_address),                    
                registered: true,
                participant: false,
                controller: _controller,
                fundAvailable: 0,
                fundCommitted: 0
            }
        );
            
        emit Registration(_address);
        
    }


    /********************************************************************************************/
    /*                          SMART CONTRACT PARTICIPANT FUNCTIONS                            */
    /********************************************************************************************/
    function fund(address _address) external payable paidEnough(10 ether) checkParticipantValue() requireIsOperational() {
        contractOwner.transfer(msg.value);

        airlines[_address].participant = true;
        airlines[_address].fundAvailable = msg.value;
    
        emit Funding(_address);
    }


    /********************************************************************************************/
    /*                                  KEYS GENEARTOR FUNCTIONS                                */
    /********************************************************************************************/
    function getInsuranceKey(address _passengerAddress, bytes32 _flightKey) pure internal returns(bytes32) {
        bytes32 _addressToBytes32 = bytes32(uint256(uint160(_passengerAddress)) << 96);
        return keccak256(abi.encodePacked(_addressToBytes32, _flightKey));
    }


    /********************************************************************************************/
    /*                          SMART CONTRACT REGISTER FLIGHT FUNCTIONS                        */
    /********************************************************************************************/
    function registerFlight(bytes32 _flightKey, string memory _flight, uint _timestamp) external requireAuthorizedCaller() requireIsOperational() {
        flights[_flightKey] = Flight({
            flightKey: _flightKey,
            flight: _flight,
            active: true,
            statusCode: 0,
            updatedTimestamp: _timestamp,
            airlineAddress: msg.sender
        });
        
        fCounter++;
        flightsReverse[fCounter] = _flightKey;
    
    }

    function checkFlight(bytes32 _flightKey) external view requireAuthorizedCaller() requireIsOperational() returns(bool) {
        bool _flightRegistered;
        
        if (flights[_flightKey].airlineAddress == address(0)) {
            _flightRegistered = false;
        }
        else {
            _flightRegistered = true;
        }

        return _flightRegistered;
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
    // // // // function buy(string memory _flight, uint _timestamp) public payable checkPassengerValue() requireAuthorizedCaller() requireIsOperational() {
    // // // //     require(!isRegistered(msg.sender) && msg.sender != contractOwner, "ERROR: CALLER IS NOT ALLOWED TO BUY INSURANCE");
        
    // // // //     //uint _timestamp = getDateTime(_year, _month, _day, _hour, _minute);
        
    // // // //     bytes32 flightKey = getFlightKey(//msg.sender, 
    // // // //         _flight, _timestamp);
        
    // // // //     require(keccak256(abi.encodePacked(flights[flightKey].flight)) == keccak256(abi.encodePacked(_flight)), "ERROR: FLIGHT NOT FOUND");
        
    // // // //     address _airlineAddress = flights[flightKey].airlineAddress;

    // // // //     bytes32 _insuranceKey = getInsuranceKey(msg.sender, flightKey);
        
    // // // //     require(insurances[_insuranceKey].flightKey != flightKey, "ERROR: PASSENGER ALREADY BOUGHT THIS FLIGHT INSURANCE");
    // // // //     contractOwner.transfer(msg.value);
    // // // //     iCounter ++;
    // // // //     insurances[_insuranceKey] = Insurance(
    // // // //         {
    // // // //             insuranceKey: _insuranceKey,
    // // // //             flightKey: flightKey,
    // // // //             passengerAddress: payable(msg.sender),
    // // // //             amountPaid: msg.value,
    // // // //             amountAvailable: 0,
    // // // //             claimable: false,
    // // // //             active: true
    // // // //         }
    // // // //     );
    // // // //     insurancesReverse[iCounter] = _insuranceKey;

    // // // //     airlines[_airlineAddress].fundAvailable = SafeMath.add(airlines[_airlineAddress].fundAvailable, msg.value);
    // // // //     airlines[_airlineAddress].fundCommitted = SafeMath.div(SafeMath.mul(msg.value, 15), 10);
        
    // // // // }

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
    function checkAirlines(address _airlineAddress) external view requireAuthorizedCaller() requireIsOperational()
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

    function checkFlights(uint _flightId) external view requireAuthorizedCaller() requireIsOperational()
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

    function checkInsurances(uint _iId) external view requireAuthorizedCaller() requireIsOperational()
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