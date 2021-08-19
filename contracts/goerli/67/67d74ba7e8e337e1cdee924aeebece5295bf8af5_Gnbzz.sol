/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.4.23;
/**
 * ERC 20 token
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Gnbzz  {
    string public constant name = "gnbzz";
    string public constant symbol = "gnbzz";
    uint public constant decimals = 18;
    uint256 public _totalSupply = 180000 * 10**decimals;
    uint public baseStartTime;
    address public founder = 0x0;
    mapping(address => uint256) balances;
    uint256 distributed = 0;
    mapping(address => uint256) reliefAddress;
    mapping(address => uint256) pledgeAmount;
    uint256 public pledgeAmountAll;
    address[] internal pledgeAddressAll;
    mapping(address => bool) pledgeAddressAllBool;
    struct node{
        bool status;
        bool ishave;
    }

    mapping(address => node) trustNode;
    address[] public trustNodes;

    mapping(address => uint256) airdrop;
    uint public airdropAll;
    uint public lastBlockNumber = 0;


    mapping(address => mapping (address => uint256)) allowed;
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint public startBlockHeight = 0;


    uint256 uBlockNumber = 0;
    mapping(uint256 => blockDetails) uBlock;
    struct blockDetails{
        uint _blockNumber;

    }

    function Gnbzz(){
        founder = msg.sender;
        baseStartTime = block.timestamp;

    }


    function pledgeAmountAll() public view returns(uint){
        return pledgeAmountAll;
    }


    function startBlockHeight() public view returns(uint){
        return startBlockHeight;
    }


    function airdropAll() public view returns(uint){
        return airdropAll;
    }


    function distributedd() public view returns(uint){
        require(msg.sender == founder);
        return distributed;
    }

    function setStartTime(uint _startTime) public returns(bool success){
        require(msg.sender == founder);
        baseStartTime = _startTime;
        return true;
    }


    function modifyOwnerFounder(address newFounder) public returns(address founders){
        require(msg.sender == founder);
        founder = newFounder;
        return founder;
    }


    function distribute(uint256 _amount, address _to) public returns (bool success){
        require(msg.sender == founder);
        require(distributed + _amount >= distributed);
        require(1 + _amount >= 1);
        balances[_to] += _amount;
        emit Transfer(0x0000000000000000000000000000000000000000,msg.sender, _amount);
        return true;
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

    function relief() public returns (bool success) {
        if(reliefAddress[msg.sender] == 0){
            balances[msg.sender] += 15 * (10**decimals);
            reliefAddress[msg.sender] += 15 * (10**decimals);
            distributed += 15 * (10**decimals);
            emit Transfer(0x0000000000000000000000000000000000000000,msg.sender, 15 * (10**decimals));
            return true;
        }else{
            require(false);
        }
    }

    function pledge() public returns(bool success){
        if(balances[msg.sender] >= 15 * (10**decimals)){
            balances[msg.sender] -= 15 * (10**decimals);
            pledgeAmount[msg.sender] += 15 * (10**decimals);
            pledgeAmountAll += 15 * (10**decimals);
            emit Transfer(msg.sender,0x1111111111111111111111111111111111111111, 15 * (10**decimals));
            if(pledgeAddressAllBool[msg.sender] == false){
                pledgeAddressAllBool[msg.sender] = true;
                pledgeAddressAll.push(msg.sender);
            }
            return true;
        }else{
            require(false);
        }
    }

    function pledgeAddressAlld() public view returns(address[]){
        return pledgeAddressAll;
    }

    function addressPledge(address _address) public view returns (uint) {
        return pledgeAmount[_address];
    }


    function setTrustNode(address _address) public returns (bool success){
        require(msg.sender == founder);
        if(trustNode[_address].ishave){
            trustNode[_address].status = true;
        }else{
            trustNode[_address].status = true;
            trustNode[_address].ishave = true;
            trustNodes.push(_address);
        }
        return true;
    }

    function deltrustNode(address _address) public returns(bool success){
        require(msg.sender == founder);
        if(trustNode[_address].ishave){
            if(trustNode[_address].status){
                trustNode[_address].status = false;
            }
        }
        return true;
    }

    function seeTrustNode() public view returns(address[] nodeaddress){
        return trustNodes;
    }

    function seeTrustNodeDetails(address _address) public view returns(bool status){
        if(trustNode[_address].ishave){
            return trustNode[_address].status;
        }else{
            return false;
        }
    }



    function airdropd(address _address) public view returns (uint256) {
        return airdrop[_address];
    }


    function uBlockNumberd() public view returns(uint256){
        return uBlockNumber;
    }


    function uBlockd(uint256 _blcoknum) public view returns(uint _blocknumber){
        return (uBlock[_blcoknum]._blockNumber);
    }


    function toDailyoutput(address[] _nodeaddress,uint _blocknumber) public returns(bool success){
        uint amountAll = 300 * (10**decimals);
        require(airdropAll < _totalSupply);
        require(_nodeaddress.length == 256);
        if(_blocknumber - lastBlockNumber != 64 ){
            if(lastBlockNumber != 0){
                require(false);
            }
        }
        if(startBlockHeight == 0){
            startBlockHeight = _blocknumber;
        }
        uBlockNumber += 1;
        uBlock[uBlockNumber]._blockNumber = _blocknumber;
        if(trustNode[msg.sender].ishave && trustNode[msg.sender].status){
            uint amount = amountAll/_nodeaddress.length;
            for(uint iii = 0; iii < _nodeaddress.length; iii++){
                if(pledgeAddressAllBool[_nodeaddress[iii]] == true){
                    airdrop[_nodeaddress[iii]] += amount;
                    airdropAll += amount;
                }
            }
        }else{
            require(false);
        }
        lastBlockNumber = _blocknumber;
        return true;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_to != msg.sender);
        require(now > baseStartTime);
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            require(false);
        }
    }
    function() payable public{
        if (!founder.call.value(msg.value)()) revert();
    }

    function killContract() public returns(bool){
        require(msg.sender == founder);
        selfdestruct(founder);
        return true;
    }
}