/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

/*
  ______  _____   ______ _____               _______
 |  ____ |     | |_____/   |   |      |      |_____|
 |_____| |_____| |    \_ __|__ |_____ |_____ |     |
                                                    
 ______   ______  _____   _____  _______    _____   ______  ______
 |     \ |_____/ |     | |_____] |______   |     | |_____/ |  ____
 |_____/ |    \_ |_____| |       ______| . |_____| |    \_ |_____|
                                                                  
*/
pragma solidity ^0.4.26;

 interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            require(c / a == b);
            return c;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GorillaDropsToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public symbol;
    string public  name;
    address public admin;
    address public reserveWallet;
    address public devWallet;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalDistributed;
    uint256 public requestMinimum;
    uint256 public tokensPerEth;
    uint256 public devWalletBalance;
    uint256 public reserveWalletBalance;
    uint256 public airdropBalance;
    uint256 public presaleBalance;
    uint256 public remainInContract;

    // ============================================================================
    // Constructor
    // ============================================================================
    constructor() public {
        symbol = "GDrops"; // token ticker
        name = "GorillaDrops.org"; // token name
        decimals = 18; // how many decimals to allow
        totalSupply = 10000000000000000000000000; // 10m total
        requestMinimum = 20000000000000000; // minimum spend 0.02 ether
        admin = 0x5A2d843Db97F7E2914b34306b316F7807399Ad83; // owner wallet address
        reserveWallet = 0x24E13f496c39BEfA243d9bf1a024d5B0c8801898; // reserve wallet address
        reserveWalletBalance = 1000000000000000000000000; // reserve balance
        
        devWallet = 0xd98cB8eAd6637355F76F97a5100Cd257fcCC1F34; // dev wallet address
        devWalletBalance = 1000000000000000000000000; //dev wallet balance

        tokensPerEth = 50000000000000000000; // presale price 50/eth

        airdropBalance = 4000000000000000000000000; // 4m airdrop

        presaleBalance = 4000000000000000000000000; // 4m presale  

        remainInContract = 8000000000000000000000000;

        // presale & airdrop; 8m, stays in this contract
        balances[this] = remainInContract;
        emit Transfer(this, this, remainInContract);

        // reserve; 1m, sent to siloed wallet
        balances[reserveWallet] = reserveWalletBalance;
        emit Transfer(this, reserveWallet, reserveWalletBalance);

        // dev; 1m, sent to siloed wallet
        balances[devWallet] = devWalletBalance;
        emit Transfer(this, devWallet, devWalletBalance);

    }

    // ============================================================================
    // Events
    // ============================================================================
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TokensPerEthUpdated(uint _tokensPerEth);
    event Burn(address indexed burner, uint256 value);
    
    // ============================================================================
    // Only owner can use functions with this modifier
    // ============================================================================
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }    
    
    // ============================================================================
    // Transfer ownership to another address
    // ============================================================================
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    // ============================================================================
    // Airdrop - Accepts a JavaScript Array passed with web3.js
    // ============================================================================
    function Airdrop(address[] dests) onlyOwner external
    {
        uint256 i = 0;
        uint256 toSend = 10 * 10**18;
        while (i < dests.length && airdropBalance >= toSend) 
        {
            
            balances[this] = balances[this].sub(toSend);
            airdropBalance.sub(toSend);

            balances[dests[i]] = balances[dests[i]].add(toSend);

            emit Transfer(address(this), dests[i], toSend);

            i++;
        }
    }

    // ============================================================================
    // When ethers are received, call the getTokens(); function
    // ============================================================================     
    function () external payable {
        getTokens();
    }

    // ============================================================================
    // Get presale or airdrop tokens
    // 0 ether - returns 1 token
    // > 0 ether - returns Sent Ethers * presale price
    // ============================================================================
    function getTokens() payable public {

        uint256 tokens = 0; // initialise to zero
        tokens = tokensPerEth.mul(msg.value) / 1 ether; // calculate purchased amount        
        uint256 selfdropTokens = 0.5 ether; // set 'good faith' airdrop rate
        uint256 etherBalance = address(this).balance; // contract eth balance

        if (tokens > 0 && msg.value >= requestMinimum)
        {
            if (presaleBalance >= tokens)
            {
                balances[this] = balances[this].sub(tokens);
                presaleBalance.sub(tokens);

                balances[msg.sender] = balances[msg.sender].add(tokens);

                emit Transfer(address(this), msg.sender, tokens);
                
                reserveWallet.transfer(msg.value);        
            }
            else
            {   
                // if thhere aren't enough tokens, refund user
                msg.sender.transfer(msg.value);        
            }
        }

        // if the user sends nothing, issue 'good faith' airdrop
        // we only issue 'good faith' airdrop to wallets who have no tokens
        // if people are going to exploit our good faith
        // we might as well make them work for it ;)
        if (tokens <= 0 && msg.value < requestMinimum && balances[msg.sender] < 1)
        {
            if (airdropBalance >= selfdropTokens)

            {

            balances[this] = balances[this].sub(selfdropTokens);
            airdropBalance.sub(selfdropTokens);


            balances[msg.sender] = balances[msg.sender].add(selfdropTokens);

            emit Transfer(address(this), msg.sender, selfdropTokens);

            reserveWallet.transfer(etherBalance);
            }
        }
    }
    // ============================================================================
    // Check balance of owner
    // ============================================================================
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // ============================================================================
    // transfer to, value
    // ============================================================================
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    // ============================================================================
    // transferFrom from, to, value
    // ============================================================================
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    // ============================================================================
    // Approve token for spending
    // ============================================================================
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
}
/*
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKKKXNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOc,...';oOXNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXo.        .cOXNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXO:.           .;oOXNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOc.                .lKNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOc.                   .:ONNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxc.                       cXNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkc'                         .dNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKOxo:'                             'xXNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0o;..                                  .xNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0l.                                      .kNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXx'                                        lXNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0kc.                                      .,l0NNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXx'                                        c0XNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKk;.                                        .kNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkl'.                                          .kNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNXKOxollc:;:llll:,.                                              'ONNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNN0dc,.                                                              lXNNNNNNNNN
NNNNNNNNNNNNNNNNNNNXk:.                                                                 ;0NNNNNNNNNN
NNNNNNNNNNNNNNNNNXk;.                                                                  ,ONNNNNNNNNNN
NNNNNNNNNNNNNNNNKl.                                                                    .xXNNNNNNNNNN
NNNNNNNNNNNNNNN0;                                                                       'ONNNNNNNNNN
NNNNNNNNNNNNNN0;                                                                        'ONNNNNNNNNN
NNNNNNNNNNNNNXl                                                                         'ONNNNNNNNNN
NNNNNNNNNNNNNk.                                                                         'ONNNNNNNNNN
NNNNNNNNNNNNXc                                                                          'ONNNNNNNNNN
NNNNNNNNNNNNx.                                                                          :KNNNNNNNNNN
NNNNNNNNNNXd.                                                      :x;                  lNNNNNNNNNNN
NNNNNNNNN0c.                  .;lxc.                               'kk;                 oNNNNNNNNNNN
NNNNNNNXx'                  .:kKXKkolc:;;,...                     .;xX0l.              .kNNNNNNNNNNN
NNNNNNNk'                  ,xx:,',:kXNNNNXK0Oxoc:,,,'.....',,;cldkKOo;:xx;             ,0NNNNNNNNNNN
NNNNNN0;                 .lkl.    ,ONNNNNNNNNNNNNNNNXK000KXXNNNNNNNo.  .cOl.           lXNNNNNNNNNNN
NNNNNKc              ..,lkx,     .oNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKk,    .x0,          .xNNNNNNNNNNNN
NNNNXd.            ,oOKOl,.       ,kNNNNNNNNNNNNNNNNNNNNNNNNNNNOc..   .:x0O,          ;KNNNNNNNNNNNN
NNNNO'           .oKNNNd.          .lOKNNNNNNNNNNNNNNNNNNNNNNNNo.    .o0o,.          .dNNNNNNNNNNNNN
NNNNd.           .dKNNNd.            .':xXNNNNNNNNNNNNNNNNNNNNNo     :0d.            ;0NNNNNNNNNNNNN
NNNNd.             .;lO0:               .xNNNNNNNNNNNNNNNNNNNNNx.   .xO,            .xNNNNNNNNNNNNNN
NNNNO'                ;00l'.............;kNNNNNNNNNNNNNNNNNNNNNXklc:dKO'           .oXNNNNNNNNNNNNNN
NNNNNk,               'kNNK000OOOOOOOOO0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKl.         .lKNNNNNNNNNNNNNNN
NNNNNNKxooooooooooooooOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0kkkkkkkkk0XNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
*/