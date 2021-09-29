/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


contract MyErc20 {
    string NAME = "MyErc20TokensReallyLongName";
    string SYMBOL = "M20";
    mapping (address => uint) balances;
    // define the balances that user 
    mapping(address => mapping(address => uint)) allowances;
    mapping(uint => bool) blockMined;
    
    address deployer;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint public transferFee = 7;
    
    constructor() {
        deployer = msg.sender;
        balances[deployer] = 1000000*1e8; // minted 1M and transferred to msg.sender
    }
    
    
    function name() public view returns (string memory){
        return NAME;
    }
    
    function symbol() public view returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() public pure returns (uint8) {
        return 8;
    }
    
    function totalSupply() public pure returns (uint256) {
        return 10000000*1e8; //10M
    }
    
    
    // to get the balance of the token in an address 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // to transfer token from msg.sender to another address, no approval is required
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "insufficient amount");
        bool sent = _transfer(msg.sender, _to, _value);
        require(sent, "transfer failed");
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    // to transfer token from one address to another, approval of amount by owner to spender prior to transfer is required
    // allowances will reflect the amount approved for the spender to transfer
    // allowances will reduce once transfer has been performed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "insufficient amount");
        require(allowances[msg.sender][_from] >= _value, "insufficient allowance");
        
        allowances[msg.sender][_from] -= _value;
        bool sent = _transfer(_from, _to, _value);
        require(sent, "transfer failed");
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // refactoring of transfer function to reduce code repetition in transfer and transferFrom functions
    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_from != address (0), "transfer from zero address");
        require(_to != address(0), "transfer to zero address");
        
        balances[_from] -= _value;
        balances[address(this)] += _value*transferFee/100;
        _value = _value - _value*transferFee/100;
        
        balances[_to] += _value;
        return true;
    }
    
    // approve function to be executed prior to running transferFrom function
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // allowance reflects the amount that has been approved by owner to spender 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    uint totalMinted = 1000000*1e8; // set the total minted amount to 10M initially 
    
    // mine function allows user to mine 10 tokens every 10th blocks
    function mine() public returns (bool success){
        // require rewards have not yet been mined
        require(!blockMined[block.number], "rewards have been mined");
        
        // require a block to be 10th block
        require(block.number % 10 == 0, "not a 10th block" ); 
        
        // require total minted to be less than max supply
        require(totalMinted <= totalSupply(), "max supply reached"); 
        
        balances[msg.sender] += 10*1e8;
        totalMinted += 10*1e8;
        blockMined[block.number] = true;
        
        return true;
    }
    
    // function to find out the current block number
    function getCurrentBlock() public view returns(uint){
        return block.number;
    }
    
    // check whether the reward of a block has been mined
    function isMined(uint blockNumber) public view returns(bool) {
        return blockMined[blockNumber];
    }
    
    
    
}