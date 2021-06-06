/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT-License
pragma abicoder v2;
pragma solidity ^0.8.1;

contract EtherBPMN {
    // Model meta-data
    
    struct ModelRecord {
        string title;
        string link;
        string hash;
        string annotation;
        string industry;
        uint256 datetime;
    }

    // Collection properties
    
    address private owner;
    
    ModelRecord[] private models;

    uint256 public modelsCount;
    uint256 public deploymentTimestamp;
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);

    // Token properties
    
    string public name;
    string public symbol;
    
    uint256 public totalSupply;
    uint256 public price;

    constructor() {
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;

        // Collection models
        
        {
            addModel(
                "Dispatch of goods",
                "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/dispatch.bpmn",
                "15a7b75c6e6940754d4dc69f185ce208a4429c420261c1fd7fe4abd7c73ef1d2",
                "This process happens at a small hardware company that ships small amounts of goods to end customers but as well big amounts to other shops",
                "Sales"
            );
            
            addModel(
                "Recourse",
                "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/recourse.bpmn",
                "a23349cfea74c81484efb3a61f6d7473fad27a3d214c33fde99fec0bacebcf6f",
                "Insurants can be forced to pay back money they received from the insurance company for different reasons. This is called recourse. Here the clerk describes how this process works",
                "Insurance"
            );
            
            addModel(
                "Credit scoring",
                "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/scoring.bpmn",
                "ef9571cdf6566d66bb94aa00d22a6e21e4686f155662b72b619050180f96d12c",
                "A credit protection agency allows customers to query a credit rating for persons via a technical interface.",
                "Finance"
            );
            
            addModel(
                "Self-service restaurant",
                "https://raw.githubusercontent.com/freebpmnquality/bpmn_structuredness/main/input/restaurant.bpmn",
                "45e8aa48ec7ad8d9bb7ef53df22aac59d47601d20fd5955f93ae189974358d7b",
                "A self-service restaurant is under chaotic conditions. Guests place their order at the till and receive their meals on call from the kitchen. As the restaurant is very popular, the processes need to be adapted to the increasing visitor numbers. In future, guests should only be in touch with one member of staff for their order. The chef should purely be concentrating on preparing the meals. Buzzers will be introduced to signalise to customers when their order has been completed.",
                "Public Catering"
            );
        }
        
        // Token properties initialization
        
        name = "EtherBPMN";
        symbol = "ETHBPMN";
        
        totalSupply = 1000000000000; // 1 trillion
        price = 200000000000; // 0.0000002 ETH

        balanceOf[address(this)] = totalSupply / 2;
        balanceOf[address(owner)] = totalSupply / 2;
    }
    
    // Token methods
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    // Exchange methods
    
    function buyTokens() payable public returns (uint256 amount) {
        amount = msg.value / price;
        
        balanceOf[address(this)] -= amount;
        balanceOf[msg.sender] += amount;

        emit Transfer(address(this), msg.sender, amount);

        return amount;
    }
    
    function sellTokens(uint256 amount) public returns (uint256 revenue) {
        require(balanceOf[msg.sender] >= amount);
        
        balanceOf[msg.sender] -= amount;
        balanceOf[address(this)] += amount;

        revenue = amount * price;
        
        require(payable(address(msg.sender)).send(revenue));
        
        emit Transfer(msg.sender, address(this), amount);

        return revenue;
    }
    
    // Collection methods

    function addModel(string memory _title, string memory _link, string memory _hash, string memory _annotation, string memory _industry) payable public {
        if (msg.sender == owner) {
            ModelRecord memory _model = ModelRecord(_title, _link, _hash, _annotation, _industry, block.timestamp);
            models.push(_model);
            modelsCount++;
        }
    }

    function readModels() view public returns (ModelRecord[] memory) {
        if (msg.sender == owner || (balanceOf[msg.sender] > (block.timestamp - deploymentTimestamp) / 86400)) {
            return models;
        }

        ModelRecord[] memory _empty;
        return _empty;
    }
}