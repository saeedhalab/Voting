// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "./IERC20.sol";

contract Voting {
    address public votingToken;
    address public owner;
    address[] public users;
    mapping(address => uint) tokenAllowance;
    mapping(address => mapping(uint => uint)) userTokenLocked;
    mapping(address => mapping(uint => bool)) userVote;
    mapping(uint => Proposal) idProposals;

    event ProposalAdded(uint id, string title, uint startTime, uint endTime);
    event Voted(address voter, uint proposalId, bool decision);
    event UserRemoved(address user);
    event TokenUnlocked(address user, uint proposalId);
    event TokenClaimed(address user, uint amount);

    struct Proposal {
        uint id;
        uint startTime;
        uint endTime;
        uint agreedVotes;
        uint disagreement;
        string title;
        bool exist;
    }

    constructor(address _votingToken) {
        votingToken = _votingToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier AllowedVote(uint id) {
        require(idProposals[id].exist, "Proposal does not exist");
        require(_isVotingTime(id), "Not in voting time");
        require(!userVote[msg.sender][id], "Already voted");
        _;
    }

    modifier isUser() {
        require(tokenAllowance[msg.sender] > 0);
        _;
    }

    function addUsers(
        address[] memory _users,
        uint amountToken
    ) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            require(tokenAllowance[_users[i]] == 0, "User already exists");
            users.push(_users[i]);
            tokenAllowance[_users[i]] = amountToken;
        }
    }

    function claimToken() public {
        uint tokenAmount = tokenAllowance[msg.sender];
        require(tokenAmount > 0);
        tokenAllowance[msg.sender] = 0;
        require(
            IERC20(votingToken).transfer(msg.sender, tokenAmount),
            "Transfer Failed"
        );
        emit TokenClaimed(msg.sender, tokenAmount);
    }

    function removeUser(address user) public onlyOwner {
        require(user != address(0));
        delete tokenAllowance[user];
        _deleteUser(user);
        emit UserRemoved(user);
    }

    function addProposal(
        uint id,
        uint start,
        uint end,
        string calldata title
    ) public onlyOwner {
        require(start < end && start > block.timestamp);
        require(!idProposals[id].exist);
        idProposals[id] = Proposal(id, start, end, 0, 0, title, true);
        emit ProposalAdded(id, title, start, end);
    }

    function vote(uint id, bool decision) public isUser AllowedVote(id) {
        require(
            IERC20(votingToken).transferFrom(msg.sender, address(this), 1),
            "Transfer failed"
        );
        userTokenLocked[msg.sender][id] = 1;
        userVote[msg.sender][id] = true;
        if (decision) {
            idProposals[id].agreedVotes += 1;
        } else {
            idProposals[id].disagreement += 1;
        }

        emit Voted(msg.sender, id, decision);
    }

    function unlockToken(uint id) public isUser {
        require(userVote[msg.sender][id],"User has not voted");
        require(idProposals[id].endTime < block.timestamp);
        delete userTokenLocked[msg.sender][id];
        require(IERC20(votingToken).transfer(msg.sender, 1), "Transfer failed");
        emit TokenUnlocked(msg.sender, id);
    }

    function showResult(
        uint id
    ) public view onlyOwner returns (uint aggre, uint disagreement) {
        require(idProposals[id].exist);
        Proposal memory proposal = idProposals[id];
        require(proposal.endTime < block.timestamp);
        return (proposal.agreedVotes, proposal.disagreement);
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

    function _isVotingTime(uint id) private view returns (bool) {
        return
            idProposals[id].exist &&
            idProposals[id].startTime <= block.timestamp &&
            idProposals[id].endTime >= block.timestamp;
    }
}
