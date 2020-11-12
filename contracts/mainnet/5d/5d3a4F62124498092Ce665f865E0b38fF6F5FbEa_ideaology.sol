//SPDX-License-Identifier: UNLICENSE
pragma solidity 0.7.0;

//SafeMath library for calculations.
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c){
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c){
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c){
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c){
        require(b > 0);
        c = a / b;
    }
}

//ideaology main contract code.
contract ideaology is SafeMath{
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public sale_token; //need function
    uint public total_sold_token;
    uint public totalSupply; //need function
    address public owner;
    uint[] public salesAmount;
    
    //sale struct declare
    struct sale{
        uint startDate;
        uint endDate;
        uint256 saletoken;
        uint256 price;
        uint256 softcap;
        uint256 hardcap;
        uint256 total_sold;
    }
    
    sale[] public sale_detail;
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(string => uint256) internal allSupplies;
    mapping(string => uint256) internal RewardDestribution;
    mapping(string => uint256) internal token_sale;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    //constructor to define all fields
    constructor(){
        symbol = "IDEA";
        name = "IDEAOLOGY";
        decimals = 18;
        totalSupply = 500000000 * 10 ** uint256(18);
        sale_token =  219160000 * 10 ** uint256(18);
        owner = msg.sender;
        
        //sale data
         salesAmount = [0, 6000000 * 10 ** uint256(18), 19160000 * 10 ** uint256(18), 194000000 * 10 ** uint256(18)];
        
        //initialize supplies
        allSupplies['operation'] = 10000000 * 10 ** uint256(18);
        allSupplies['plateform_developement'] = 150000000 * 10 ** uint256(18);
        allSupplies['marketing'] = 25000000 * 10 ** uint256(18);
        allSupplies['team'] = 15000000 * 10 ** uint256(18);
        
        //initialize RewardDestribution
    	RewardDestribution['twitter'] = 2990000 * 10 ** uint256(18);
        RewardDestribution['facebook'] = 3450000 * 10 ** uint256(18);
        RewardDestribution['content'] = 6900000 * 10 ** uint256(18);
        RewardDestribution['youtube'] = 2760000 * 10 ** uint256(18);
        RewardDestribution['telegram'] = 4600000 * 10 ** uint256(18);
        RewardDestribution['instagram'] = 2300000 * 10 ** uint256(18);
        RewardDestribution['event'] = 1000000 * 10 ** uint256(18);
        RewardDestribution['quiz'] = 500000 * 10 ** uint256(18);
        RewardDestribution['partnership'] = 5500000 * 10 ** uint256(18);
        
        //initialize balance
        balances[owner] = totalSupply - sale_token - (200000000 * 10 ** uint256(18)) - (30000000 * 10 ** uint256(18));
    }
    
    modifier onlyOwner {
        require(msg.sender == owner,"Only Access By Admin!!");
        _;
    }
    
    //Fucntion to Get Owner Address
    function getOwnerAddress() public view returns(address ownerAddress){
        return owner;
    }
    
    //Function to Transfer the Ownership
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        uint _value = balances[msg.sender];
        balances[msg.sender] = safeSub(balances[msg.sender],_value);
        balances[newOwner] = safeAdd(balances[newOwner], _value);
        emit Transfer(msg.sender, newOwner, _value);
    }
    
    //Fucntion to Start Pre-Sale.
    function start_sale(uint _startdate, uint _enddate, uint _price, uint _softcap, uint _hardcap) public onlyOwner returns (bool status){
        uint chck = sale_detail.length;
        if( chck == 3) {
            revert("All private sale is set");
        }
        uint _softcapToken = safeDiv(_softcap, _price);
        uint _hardcapToken = safeDiv(_hardcap, _price); 
        
        
        if(_startdate < _enddate && _startdate > block.timestamp && _softcap < _hardcap && _softcapToken < salesAmount[chck + 1] && _hardcapToken < salesAmount[chck + 1]){
            
            sale memory p1= sale(_startdate, _enddate, salesAmount[chck + 1], _price, _softcap, _hardcap, 0);
            sale_detail.push(p1);
            sale_token = safeSub(sale_token, salesAmount[chck + 1]);
        }
        else{
            revert("Invalid data provided to start presale");
        }
        return true;
    }
    
    //Function to transfer token from different supply    
    function transferFromAllSupplies(address receiver, uint numTokens, string memory _supply) public onlyOwner returns (bool status) {
        require(numTokens <= allSupplies[_supply], "Token amount is larger than token distribution allocation");
        allSupplies[_supply] = safeSub(allSupplies[_supply], numTokens);
        balances[receiver] = safeAdd(balances[receiver],numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
     
    //Function to transfer token from reward   
    function transferRewards(address receiver, uint numTokens, string memory community) public onlyOwner returns (bool status) {
        require(numTokens <= RewardDestribution[community], "Token amount is larger than token distribution allocation");
        RewardDestribution[community] = safeSub(RewardDestribution[community], numTokens);
        balances[receiver] = safeAdd(balances[receiver],numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    //Function to purchase token.
    function purchase (address _account,uint _token) onlyOwner public returns (bool status){
        bool isSend = false;
        for (uint i=0; i < sale_detail.length; i++){
            if (block.timestamp >= sale_detail[i].startDate && block.timestamp <=sale_detail[i].endDate){
                if(_token <= sale_detail[i].saletoken){
                    sale_detail[i].saletoken = safeSub(sale_detail[i].saletoken, _token);
                    balances[_account] = safeAdd(balances[_account], _token);
                    total_sold_token = safeAdd(total_sold_token, _token);
                    sale_detail[i].total_sold = safeAdd(sale_detail[i].total_sold,_token);
                    emit Transfer(msg.sender, _account, _token);
                    isSend = true;
                    return true;
                }
                else{
                    revert("Check available token balances");
                }
            }
        }
        if(!isSend){
            require (balances[msg.sender] >= _token,"All Token Sold!");
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            balances[_account] = safeAdd(balances[_account], _token);
            total_sold_token = safeAdd(total_sold_token, _token);
            emit Transfer(msg.sender, _account, _token);
            return true;
        }
    }
    
    //Function to burn the token from his account.
    function burn(uint256 value) onlyOwner public returns (bool success){
        require(balances[owner] >= value);
        balances[owner] =safeSub(balances[owner], value);
        emit Transfer(msg.sender, address(0), value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    //Function to transfer token by owner.
    function transfer(address to, uint tokens) public returns (bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        total_sold_token = safeAdd(total_sold_token, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //Function to Approve user to spend token.
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //Fucntion to transfer token from address.
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    //Fucntion to stop reciving ETH
    fallback() external {
       revert('contract does not accept ether'); // Reject any accidental Ether transfer
    }

    //Function for Allowance.
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];
    }
    
    //Function to get presale length
    function getsaleDetails() public view returns (uint presalelength) {
        return sale_detail.length;
    }
    
    //Function to check balance.
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    
    //Function to display reward balance
    function viewReward() public view returns (uint twitterToken, uint facebookToken, uint contentToken, uint youtubeToken, uint telegramToken, uint instagramToken, uint quizToken, uint partnershipToken){
        return (RewardDestribution['twitter'],RewardDestribution['facebook'], RewardDestribution['content'], RewardDestribution['youtube'], RewardDestribution['telegram'], RewardDestribution['instagram'], RewardDestribution['quiz'], RewardDestribution['partnership']);
    }
    
    //Function to display supplies balance
    function viewSupplies() public view returns (uint operationToken, uint plateform_developementToken, uint marketingToken, uint teamToken){
        return (allSupplies['operation'],allSupplies['plateform_developement'], allSupplies['marketing'], allSupplies['team']);
    }
    
    //Function to get presale length
    function countTotalSales() public view returns (uint count) {
        return sale_detail.length;
    }
}