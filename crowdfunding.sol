// SPDX-License-Identifier: GPL-3.0-or-above

pragma solidity ^0.8.0;

contract crowdFunding {
    mapping(address => uint256) public contributors;
    address public manager;
    uint256 public target;
    uint256 public deadline;
    uint256 public minContribution;
    uint256 public noOfContributors;
    uint256 public raisedAmount;

    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        manager = msg.sender;
        minContribution = 100 wei;
        deadline = block.timestamp + _deadline;
    }

    function sendmoney() public payable {
        require(block.timestamp < deadline, "deadline has passed");
        require(msg.value >= minContribution, "please send minimum amount");

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function refund() public {
        require(
            block.timestamp > deadline && raisedAmount < target,
            "you are not eligible"
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;
    uint256 public numRequests;

    modifier onlyManager() {
        require(msg.sender == manager, "only manager can call this function");
        _;
    }

    function createRequest(
        string memory _description,
        address payable _address,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _address;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint256 _requestNumber) public {
        require(contributors[msg.sender] > 0, "you must be a contributor");
        Request storage thisRequest = requests[_requestNumber];
        require(
            thisRequest.voters[msg.sender] == false,
            "you have already voted"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint256 _requestNumber) public onlyManager {
        require(raisedAmount >= target);
        Request storage thisRequest = requests[_requestNumber];
        require(
            thisRequest.completed == false,
            "this request has been completed"
        );
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "majority doesnot support"
        );

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
