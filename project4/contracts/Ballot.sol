// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title VOTING WITH DELEGATION.
contract Ballot {
    // THIS DECLARES A NEW COMPLEX TYPE WHICH WILL BE USED FOR VARIABLES LATER. IT WILL REPRESENT A SINGLE VOTER.
    struct Voter {
        uint weight; // WEIGHT IS ACCUMULATED BY DELEGATION
        bool voted;  // IF TRUE, THAT PERSON ALREADY VOTED
        address delegate; // PERSON DELEGATED TO
        uint vote;   // INDEX OF THE VOTED PROPOSAL
    }
    // THIS IS A TYPE FOR A SINGLE PROPOSAL.
    struct Proposal {
        bytes32 name;   // SHORT NAME (UP TO 32 BYTES)
        uint voteCount; // NUMBER OF ACCUMULATED VOTES
    }
    address public chairperson;
    // THIS DECLARES A STATE VARIABLE THAT STORES A `VOTER` STRUCT FOR EACH POSSIBLE ADDRESS.
    mapping(address => Voter) public voters;
    // A DYNAMICALLY-SIZED ARRAY OF `PROPOSAL` STRUCTS.
    Proposal[] public proposals;

    /// CREATE A NEW BALLOT TO CHOOSE ONE OF `PROPOSALNAMES`.
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // FOR EACH OF THE PROVIDED PROPOSAL NAMES, CREATE A NEW PROPOSAL OBJECT AND ADD IT TO THE END OF THE ARRAY.
        for (uint i = 0; i < proposalNames.length; i++) {
            // `PROPOSAL({...})` CREATES A TEMPORARY PROPOSAL OBJECT AND `PROPOSALS.PUSH(...)` APPENDS IT TO THE END OF `PROPOSALS`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // GIVE `VOTER` THE RIGHT TO VOTE ON THIS BALLOT. MAY ONLY BE CALLED BY `CHAIRPERSON`.
    function giveRightToVote(address voter) public {
        // IF THE FIRST ARGUMENT OF `REQUIRE` EVALUATES TO `FALSE`, EXECUTION TERMINATES AND ALL CHANGES TO THE STATE AND TO ETHER BALANCES ARE REVERTED.
        require(msg.sender == chairperson, "ONLY CHAIRPERSON CAN GIVE RIGHT TO VOTE.");
        require(!voters[voter].voted, "THE VOTER ALREADY VOTED.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /// DELEGATE YOUR VOTE TO THE VOTER `TO`.
    function delegate(address to) public {
        // ASSIGNS REFERENCE
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "YOU ALREADY VOTED.");
        require(to != msg.sender, "SELF-DELEGATION IS DISALLOWED.");

        // FORWARD THE DELEGATION AS LONG AS `TO` ALSO DELEGATED.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        // SINCE `SENDER` IS A REFERENCE, THIS MODIFIES `VOTERS[MSG.SENDER].VOTED`
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // IF THE DELEGATE ALREADY VOTED, DIRECTLY ADD TO THE NUMBER OF VOTES
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // IF THE DELEGATE DID NOT VOTE YET, ADD TO HER WEIGHT.
            delegate_.weight += sender.weight;
        }
    }

    /// GIVE YOUR VOTE (INCLUDING VOTES DELEGATED TO YOU) TO PROPOSAL `PROPOSALS[PROPOSAL].NAME`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "HAS NO RIGHT TO VOTE");
        require(!sender.voted, "ALREADY VOTED.");
        sender.voted = true;
        sender.vote = proposal;

        // IF `PROPOSAL` IS OUT OF THE RANGE OF THE ARRAY, THIS WILL THROW AUTOMATICALLY AND REVERT ALL CHANGES.
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev COMPUTES THE WINNING PROPOSAL TAKING ALL PREVIOUS VOTES INTO ACCOUNT.
    function winningProposal() public view returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // CALLS WINNINGPROPOSAL() FUNCTION TO GET THE INDEX OF THE WINNER CONTAINED IN THE PROPOSALS ARRAY AND THEN RETURNS THE NAME OF THE WINNER
    function winnerName() public view returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}