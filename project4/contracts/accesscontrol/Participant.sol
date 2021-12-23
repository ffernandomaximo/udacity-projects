// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the library 'Roles'
import "./Roles.sol";

// Define a contract 'Participant' to manage this role - add, remove, check
contract Participant {
  using Roles for Roles.Role;

  // Define 2 events, one for Adding, and other for Removing
  event ParticipantAdded(address indexed account);
  event ParticipantRemoved(address indexed account);

  // Define a struct 'participants' by inheriting from 'Roles' library, struct Role
  Roles.Role private participants;

  // In the constructor make the address that deploys this contract the 1st participant
  constructor() {
    _addParticipant(msg.sender);
  }

  // Define a modifier that checks to see if msg.sender has the appropriate role
  modifier onlyParticipant() {
    require(isParticipant(msg.sender));
    _;
  }

  // Define a function 'isParticipant' to check this role
  function isParticipant(address account) public view returns (bool) {
    return participants.has(account);    
  }

  // Define a function 'addParticipant' that adds this role
  function addParticipant(address account) public onlyParticipant {
    _addParticipant(account);
  }

  // Define a function 'renounceParticipant' to renounce this role
  function renounceParticipant() public {
    _removeParticipant(msg.sender);
  }

  // Define an internal function '_addParticipant' to add this role, called by 'addParticipant'
  function _addParticipant(address account) internal {
    participants.add(account);
    emit ParticipantAdded(account);    
  }

  // Define an internal function '_removeParticipant' to remove this role, called by 'removeParticipant'
  function _removeParticipant(address account) internal {
    participants.remove(account);
    emit ParticipantRemoved(account);   
  }
}