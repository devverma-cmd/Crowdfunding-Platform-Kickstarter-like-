// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Crowdfunding {
    struct Campaign {
        address creator;
        string title;
        string description;
        uint goal;
        uint deadline;
        uint pledged;
        bool claimed;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledges;

    event CampaignCreated(uint campaignId, address creator, uint goal, uint deadline);
    event Pledged(uint campaignId, address pledger, uint amount);
    event Unpledged(uint campaignId, address pledger, uint amount);
    event Claimed(uint campaignId);
    event Refunded(uint campaignId, address pledger, uint amount);

    function createCampaign(string calldata _title, string calldata _description, uint _goal, uint _duration) external {
        require(_goal > 0, "Goal must be > 0");
        campaignCount++;
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            deadline: block.timestamp + _duration,
            pledged: 0,
            claimed: false
        });
        emit CampaignCreated(campaignCount, msg.sender, _goal, block.timestamp + _duration);
    }

    function pledge(uint _id) external payable {
        Campaign storage c = campaigns[_id];
        require(block.timestamp < c.deadline, "Campaign over");
        require(msg.value > 0, "Must pledge > 0");

        c.pledged += msg.value;
        pledges[_id][msg.sender] += msg.value;

        emit Pledged(_id, msg.sender, msg.value);
    }

    function claim(uint _id) external {
        Campaign storage c = campaigns[_id];
        require(msg.sender == c.creator, "Not creator");
        require(block.timestamp >= c.deadline, "Not ended");
        require(c.pledged >= c.goal, "Goal not reached");
        require(!c.claimed, "Already claimed");

        c.claimed = true;
        payable(c.creator).transfer(c.pledged);
        emit Claimed(_id);
    }

    function refund(uint _id) external {
        Campaign storage c = campaigns[_id];
        require(block.timestamp >= c.deadline, "Not ended");
        require(c.pledged < c.goal, "Goal met");

        uint bal = pledges[_id][msg.sender];
        require(bal > 0, "Nothing to refund");

        pledges[_id][msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Refunded(_id, msg.sender, bal);
    }
}
