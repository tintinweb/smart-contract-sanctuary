/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity >=0.7.0 <0.9.0;


contract PatelCoin{

    uint MINING_REWARD = 10 * 1e8;
    uint totalMined;

    event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 allowance);

    string public TOKEN_NAME = "Patel Coin";
    string public TOKEN_SYMBOL = "PC";

    address contractOwner;

    mapping (address => uint) balances;
    mapping (uint => bool) blockMining_status;
    mapping (address => mapping(address => uint)) approvalAllowance;


    //constructor
    constructor(){
        contractOwner = msg.sender;
        balances[contractOwner] = 1000000 * 1e8; //1 Million
        totalMined = 1000000 * 1e8;

    }

    
    function name() public view returns (string memory){
        return TOKEN_NAME;     //returns token's name
    }
    
    function symbol() public view returns (string memory) {
        return TOKEN_SYMBOL;   //returns token's symbol
    }
    
    function decimals() public pure returns (uint8) {
        return 8;  //every balance will be divided by 10^8 due to lowest domination (10^18).
    }
    
    function totalSupply() public pure returns (uint256) {
        return (10000000 * 1e8); //10 Million * 10^8 because decimal is 8
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];    //return token balance of the owner
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] > _value);      //check if the caller has enough tokens
        balances[msg.sender] -= _value;             //debit the caller's account
        balances[_to] += _value;                    //credit the recipient account

        emit Transfer(msg.sender, _to, _value);
        return true;                                //return success 
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        assert(balances[_from] >= _value);
        assert(approvalAllowance[_from][msg.sender] >= _value);
        approvalAllowance[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] >= _value);
        approvalAllowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return approvalAllowance[_owner][_spender];
    }

    function mine() public returns (bool success){
        //every 10th block, the block can be mined for reward of 10 tokens.

        require(totalMined < totalSupply(), "All tokens are mined and in circulation");     //check if tokens's can be mined or not
        require(block.number % 10 == 0, "Block is not allowed to be mined");    //check if current block is mineable
        require(isMined(block.number) == false, "mining reward has already been claimed for this block");   //check if current block is mined;
        balances[msg.sender] += MINING_REWARD;      //add mining reward to the caller's balance
        blockMining_status[block.number] = true;    //set block's mining status to true
        totalMined += MINING_REWARD;                //add mining reward to the accumulator
        return true;                                //return success

    }

    function getBlockNumber() public view returns (uint blockNum){
        return block.number;       //return the current blocknumber
    }

    function isMined(uint blockNumber) public view returns (bool claimStatus){
        return blockMining_status[blockNumber];        //return the mining status of the block
    }
    
    
}