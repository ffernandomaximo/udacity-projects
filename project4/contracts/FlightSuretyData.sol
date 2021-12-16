// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    struct Airline {
        address airlineAddress;
        uint32  airlineId;
        bool    isRegistered;
        bool    isParticpant;
    }
    mapping(address => Airline) private airlines;

    uint32 mapSize;

    address _firsAirlineAddress;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                )  
    {
        contractOwner = msg.sender;
        mapSize = 1;
        _firsAirlineAddress = 0xF258b0a25eE7D6f02a9a1118afdF77CaC6D72784;
        airlines[_firsAirlineAddress] = Airline(
            {
                airlineAddress: _firsAirlineAddress,
                airlineId: mapSize,
                isRegistered: true,
                isParticpant: false
            });
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "CONTRACT IS CURRENTLY NOT OPERATIONAL");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "CALLER IS NOT CONTRACT OWNER");
        _;
    }

    modifier requireRegister()
    {
        require(airlines[msg.sender].airlineId <= 4, "CALLER IS NOT A REGISTER");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
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

   /**
    * @dev Check if an employee is registered
    *
    * @return A bool that indicates if the employee is registered
    */   
    function isAirlineRegistered
                            (
                                address _address
                            )
                            external
                            view
                            returns(bool)
    {
        return airlines[_address].isRegistered;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
   /**
    * @dev Check if an employee is registered
    *
    * @return A bool that indicates if the employee is registered
    */
    function setParticipant
                            (
                                address _addressParticipant
                            ) 
                            external
                            isAirlineRegistered(_addressParticipant)
    {
        airlines[_addressParticipant].airlineAddress.transfer(contracOwner);
    }

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address _address
                            )
                            external
                            requireRegister()
    {
        require(!airlines[_address].isRegistered, "ERROR: AIRLINE IS ALREADY REGISTERED");
        mapSize++;
        airlines[_address] = Airline(
            {
                airlineAddress: _address,
                airlineId: mapSize,
                isRegistered: true,
                isParticpant: false
            }); 
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
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

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

