// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define a contract 'Supplychain'
import "./accesscontrol/Controller.sol";
import "./accesscontrol/Participant.sol";
import "./accesscontrol/Registered.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData is Controller, Participant, Registered {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address payable contractOwner;                                      // ACCOUNT USED TO DEPLOY CONTRACT
    bool private operational = true;                                    // BLOCKS ALL STATE CHANGES THROUGHOUT THE CONTRACT IF FALSE
    struct Airline {
        uint    aId;
        address payable aAddress;
        bool    isRegistered;
        bool    isParticipant;
        bool    isController;
    }
    mapping(uint => Airline) private airlines;
    uint constant M = 2;
    address[] multiCalls = new address[](0);

    struct Passenger {
        uint    pId;
        address pAddress;
    }
    mapping(uint => Passenger) private passengers;

    uint _aId;

    uint participantFund = 10;

    /********************************************************************************************/
    /*                                       CONSTRUCTOR DEFINITION                             */
    /********************************************************************************************/
    
    /* The deploying account becomes contractOwner */
    constructor() {
        address _firsAAddress;
        contractOwner = payable(msg.sender);
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
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Registration(uint aId);
    event Funding(uint aId);
    event Acquisition(uint aId);
    event Payment(uint aId);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireIsOperational() 
    {
        require(operational, "CONTRACT IS CURRENTLY NOT OPERATIONAL");
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address, "CALLER IS NOT ALLOWED TO EXECUTE FUNCTION"); 
        _;
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

    function kill() public {
        if (msg.sender == contractOwner) {
            selfdestruct(contractOwner);
        }
    }

    function isOperational() public view returns(bool) 
    {
        return operational;
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
    function registerAirline(address _aAddress) external requireIsOperational() //requireController() requireIsOperational()
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
                }
            );
            register(_aAddress);
            if (airlines[_aId].aId <= 5) {
                airlines[_aId].isController = true;
                addController(airlines[_aId].aAddress);
            }
            
            emit Registration(_aId);
        }
    }

    function fund(uint _aId2) public payable verifyCaller(airlines[_aId2].aAddress) onlyRegistered() //paidEnough(participantFund) //checkValue()
    {
        require(!isParticipant(airlines[_aId2].aAddress), "ERROR: AIRLINE IS ALREADY A PARTICIPANT");
        contractOwner.transfer(10);
        airlines[_aId2].isParticipant = true;
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


    function checkAirlines(uint _aId3) public view returns(address aAddress, bool isRegistered, bool isParticipant, bool isController) {
        return(airlines[_aId3].aAddress
            , airlines[_aId3].isRegistered
            , airlines[_aId3].isParticipant
            , airlines[_aId3].isController
        );
    }
}