// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'Registered' to manage this role - add, remove, check
contract Registered {
  using Roles for Roles.Role;

  // Define 2 events, one for Adding, and other for Removing
  event Register(address indexed account);
  event Deregister(address indexed account);

  // Define a struct 'registers' by inheriting from 'Roles' library, struct Role
  Roles.Role private registers;

  // In the constructor make the address that deploys this contract the 1st controller
  constructor() {
    _register(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyRegistered() {
    require(isRegistered(msg.sender));
    _;
  }

  // Define a function 'isRegistered' to check this role
  function isRegistered(address account) public view returns (bool) {
    return registers.has(account);    
  }

  // Define a function 'register' that adds this role
  function register(address account) public onlyRegistered {
    _register(account);
  }

  // Define a function 'deregister' to renounce this role
  function deregister() public {
    _deregister(msg.sender);
  }

  // Define an internal function '_register' to add this role, called by 'register'
  function _register(address account) internal {
    registers.add(account);
    emit Register(account);    
  }

  // Define an internal function '_deregister' to remove this role, called by 'removeController'
  function _deregister(address account) internal {
    registers.remove(account);
    emit Deregister(account);   
  }
}