/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT-License
pragma abicoder v2;
pragma solidity ^0.8.1;

contract ModelsCollection {
    address private Owner;

    struct ModelRecord {
        string Title;
        string Link;
        string Hash;
        string Annotation;
        string Industry;
        uint256 DateTime;
    }

    ModelRecord[] private Models;

    uint256 public ModelsCount;
    
    uint256 public Timestamp;

    constructor() {
        Owner = msg.sender;
        Timestamp = block.timestamp;

        // Default models
        AddModel(
            "Dispatch of goods",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/dispatch.bpmn",
            "15a7b75c6e6940754d4dc69f185ce208a4429c420261c1fd7fe4abd7c73ef1d2",
            "This process happens at a small hardware company that ships small amounts of goods to end customers but as well big amounts to other shops",
            "Sales"
        );
        AddModel(
            "Recourse",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/recourse.bpmn",
            "a23349cfea74c81484efb3a61f6d7473fad27a3d214c33fde99fec0bacebcf6f",
            "Insurants can be forced to pay back money they received from the insurance company for different reasons. This is called recourse. Here the clerk describes how this process works",
            "Insurance"
        );
        AddModel(
            "Credit scoring",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/scoring.bpmn",
            "ef9571cdf6566d66bb94aa00d22a6e21e4686f155662b72b619050180f96d12c",
            "A credit protection agency allows customers to query a credit rating for persons via a technical interface.",
            "Finance"
        );
        AddModel(
            "Self-service restaurant",
            "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/restaurant.bpmn",
            "45e8aa48ec7ad8d9bb7ef53df22aac59d47601d20fd5955f93ae189974358d7b",
            "A self-service restaurant is under chaotic conditions. Guests place their order at the till and receive their meals on call from the kitchen. As the restaurant is very popular, the processes need to be adapted to the increasing visitor numbers. In future, guests should only be in touch with one member of staff for their order. The chef should purely be concentrating on preparing the meals. Buzzers will be introduced to signalise to customers when their order has been completed.",
            "Public Catering"
        );
        
        // token features
        name = "EtherBPMN";
        symbol = "ETHBPMN";
        totalSupply = 10000;
        tokenPrice = 10000000000000;
        
        balanceOf[address(this)] = 0;
        balanceOf[Owner] = totalSupply;
    }
    
    // [start] token features
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public tokenPrice;
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function buyTokens() payable public returns (uint amount) {
        amount = msg.value / tokenPrice;
        
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        
        emit Transfer(address(this), msg.sender, amount);

        return amount;
    }
    
    function claimAirdrop() public returns (uint revenue) {
        revenue = 10;
        
        balanceOf[msg.sender] += revenue;
        totalSupply += revenue;
        
        emit Transfer(address(this), msg.sender, revenue);
        
        return revenue;
    }
    // [end] token features

    function AddModel(
        string memory _Title,
        string memory _Link,
        string memory _Hash,
        string memory _Annotation,
        string memory _Industry
    ) public {
        if (msg.sender == Owner) {
            ModelRecord memory _Model =
                ModelRecord(
                    _Title,
                    _Link,
                    _Hash,
                    _Annotation,
                    _Industry,
                    block.timestamp
                );
            Models.push(_Model);
            ModelsCount++;
        }
    }

    function ReadModels() view public returns (ModelRecord[] memory) {
        if (balanceOf[msg.sender] > (block.timestamp - Timestamp) / 86400) {
            return Models;
        }

        ModelRecord[] memory _Empty;
        return _Empty;
    }
}