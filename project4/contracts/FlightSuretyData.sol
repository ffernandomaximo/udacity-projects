// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define a contract 'Supplychain'
import './accesscontrol/ControllerRole.sol';
import './accesscontrol/ParticipantRole.sol';
import './core/Ownable.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData is ControllerRole, ParticipantRole, Ownable {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    struct Airline {
        uint    aId;
        address aAddress;
        bool    isRegistered;
        bool    isParticpant;
        bool    isController;
    }
    mapping(uint => Airline) private airlines;

    struct Passenger {
        uint    pId;
        address pAddress;
    }
    mapping(uint => Passenger) private passengers;

    uint _aId;

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
                aAddress: _firsAAddress,
                isRegistered: true,
                isParticpant: false,
                isController: true
            });
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

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner() 
    {
        if ( isOperational() != mode ) {
            operational = mode;
        }
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    function registerAirline
                            (
                                address _aAddress
                            )
                            external
                            onlyController()
    {
        _aId ++;
        require(!airlines[_aId].isRegistered, "ERROR: AIRLINE IS ALREADY REGISTERED");
        airlines[_aId] = Airline(
            {
                aId: _aId,
                aAddress: _aAddress,
                isRegistered: true,
                isParticpant: false,
                isController: false
            }); 
        if (airlines[_aId].aId <= 5) {
            addController(airlines[_aId].aAddress);
            airlines[_aId].isController = true;
        }
    }

    function fund
                            (   
                            )
                            public
                            payable
    {
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
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


}

