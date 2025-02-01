// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./IERC20.sol";

contract Voting {
    address public votingToken;
    address public owner;
    address[] public users;
    mapping(address => uint) tokenAllowance;
    mapping(address => uint) userVote;
    Proposal[] proposals;

    struct Proposal {
        uint id;
        uint startTime;
        uint endTime;
        uint agreedVotes;
        uint disagreement;
        string title;
    }

    constructor(address _votingToken) {
        votingToken = _votingToken;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAllowedTimeVote(uint proposalId) {
        Proposal memory proposal = FindProposal(proposalId);
        require(proposal.startTime > block.timestamp);
        require(proposal.endTime < block.timestamp);
        _;
    }

    modifier isUser() {
        address user;
        for (uint i = 0; i < users.length; i++) {
            if (msg.sender == users[i]) {
                user = users[i];
            }
        }
        require(user != address(0));
        _;
    }

    function addUsers(
        address[] memory _users,
        uint amountToken
    ) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            users.push(_users[i]);
            tokenAllowance[_users[i]] = amountToken;
        }
    }

    function claimedToken() public {
        uint tokenAmount = tokenAllowance[msg.sender];
        require(tokenAmount > 0);
        require(IERC20(votingToken).transfer(msg.sender, tokenAmount));
    }

    function removeUser(address user) public onlyOwner {
        require(user != address(0));
        _deleteUser(user);
    }

    function AddProposal(
        uint id,
        uint start,
        uint end,
        string memory title
    ) public onlyOwner {
        require(start < end && start > block.timestamp);
        require(!isExistProposal(id));
        proposals.push(Proposal(id, start, end, 0, 0, title));
    }

    function showResult(
        uint id
    ) public view onlyOwner returns (uint aggre, uint disagreement) {
        require(isExistProposal(id));
        Proposal memory proposal = FindProposal(id);
        require(proposal.endTime >= block.timestamp);
        return (proposal.agreedVotes, proposal.disagreement);
    }

    function FindProposal(
        uint proposalId
    ) public view returns (Proposal memory proposal) {
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == proposalId) {
                return proposals[i];
            }
        }
    }

    function _deleteUser(address _user) private {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                delete users[i];
                users[i] = users[users.length - 1];
                users.pop();
                return;
            }
        }
    }

    function isExistProposal(uint id) public view returns (bool) {
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].id == id) {
                return true;
            }
        }
        return false;
    }
}
