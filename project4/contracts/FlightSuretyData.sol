// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define a contract 'Supplychain'
import './accesscontrol/Controller.sol';
import './accesscontrol/Participant.sol';
import './accesscontrol/Registered.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData is Controller, Participant, Registered {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    struct Airline {
        uint    aId;
        address payable aAddress;
        bool    isRegistered;
        bool    isParticipant;
        bool    isController;
    }
    mapping(uint => Airline) private airlines;

    struct Passenger {
        uint    pId;
        address pAddress;
    }
    mapping(uint => Passenger) private passengers;

    uint _aId;

    uint participantFund = 10;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    
    /* The deploying account becomes contractOwner */
    constructor() {
        address _firsAAddress;
        contractOwner = msg.sender;
        _aId = 1;
        _firsAAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
        airlines[_aId] = Airline(
            {
                aId: _aId,
                aAddress: payable(_firsAAddress),
                isRegistered: true,
                isParticipant: false,
                isController: true
            });
        register(_firsAAddress);
        addController(_firsAAddress);
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireIsOperational() 
    {
        require(operational, "CONTRACT IS CURRENTLY NOT OPERATIONAL");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "CALLER IS NOT CONTRACT OWNER");
        _;
    }

    modifier requireController()
    {
        require(msg.sender == contractOwner || isController(msg.sender), "CALLER IS NOT CONTROLLER");
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address, "CALLER IS NOT ALLOWED TO EXECUTE FUNCTION"); 
        _;
    }

    modifier paidEnough(uint _price) { 
        require(msg.value >= _price, "AMOUNT IS NOT ENOUGHT"); 
        _;
    }
  
    modifier checkValue() {
        uint amountToReturn = msg.value - participantFund;
        payable(contractOwner).transfer(amountToReturn);
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) 
    {
        return operational;
    }

    function setOperatingStatus (bool mode) external requireContractOwner() 
    {
        if ( isOperational() != mode ) {
            operational = mode;
        }
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    function registerAirline(address _aAddress) external requireController()
    {
        require(!isRegistered(_aAddress), "ERROR: AIRLINE IS ALREADY REGISTERED");
        _aId ++;
        if(_aId < 5) {
            airlines[_aId] = Airline(
                {
                    aId: _aId,
                    aAddress: payable(_aAddress),
                    isRegistered: true,
                    isParticipant: false,
                    isController: false
                });
            register(_aAddress);
            if (airlines[_aId].aId <= 5) {
                airlines[_aId].isController = true;
                addController(airlines[_aId].aAddress);
            }
        }
    }

    function fund(uint _aId) public payable verifyCaller(airlines[_aId].aAddress) onlyRegistered() paidEnough(participantFund) checkValue()
    {
        require(!isParticipant(msg.sender), "ERROR: AIRLINE IS ALREADY A PARTICIPANT");
        payable(contractOwner).transfer(10);
        airlines[_aId].isParticipant = true;
        addParticipant(msg.sender);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy() external payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
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


    function checkAirlines(uint _aId) public view returns(
        address aAddress, bool isRegistered, bool isParticipant, bool isController
    ) {
        return(airlines[_aId].aAddress
            , airlines[_aId].isRegistered
            , airlines[_aId].isParticipant
            , airlines[_aId].isController
        );
    }


}