// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'ControllerRole' to manage this role - add, remove, check
contract ControllerRole {
  using Roles for Roles.Role;

  // Define 2 events, one for Adding, and other for Removing
  event ControllerAdded(address indexed account);
  event ControllerRemoved(address indexed account);

  // Define a struct 'controllers' by inheriting from 'Roles' library, struct Role
  Roles.Role private controllers;

  // In the constructor make the address that deploys this contract the 1st controller
  constructor() {
    _addController(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyController() {
    require(isController(msg.sender));
    _;
  }

  // Define a function 'isController' to check this role
  function isController(address account) public view returns (bool) {
    return controllers.has(account);    
  }

  // Define a function 'addController' that adds this role
  function addController(address account) public onlyController {
    _addController(account);
  }

  // Define a function 'renounceController' to renounce this role
  function renounceController() public {
    _removeController(msg.sender);
  }

  // Define an internal function '_addController' to add this role, called by 'addController'
  function _addController(address account) internal {
    controllers.add(account);
    emit ControllerAdded(account);    
  }

  // Define an internal function '_removeController' to remove this role, called by 'removeController'
  function _removeController(address account) internal {
    controllers.remove(account);
    emit ControllerRemoved(account);   
  }

  function checkController() onlyController() public view returns (address) {
     return msg.sender;
  }
}