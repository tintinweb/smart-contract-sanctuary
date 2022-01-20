/**
 *Submitted for verification at FtmScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/libraries/AddressArrayLibrary.sol


pragma solidity >=0.8.0;

library AddressArrayLib {

    function removeItem(
        address[] storage array,
        address a
    ) internal {
        int i = indexOf(array, a);
        require(i != -1, "ARRAY_LIB: Element doesn't exist");
        remove(array, uint(i));
    }

    function remove(      
        address[] storage array,
        uint index
    ) internal {
        require(index <= array.length, "ARRAY_LIB: Index does not exist");
        array[index] = array[array.length-1];
        array.pop();
    }


    // probably not the best way to find index
    function indexOf(
        address[] storage array,
        address a
    ) internal view returns (int) {
        if (array.length == 0) return int(-1); // we want to continue txn process
        for(uint i=0; i<array.length; i++) {
            if (array[i] == a) {
                return int(i);
            }
        }
        return int(-1);
    }
}

// File: contracts/interfaces/IERC20.sol


pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

// File: contracts/CompoundStaking.sol


pragma solidity 0.8.8;



//import "hardhat/console.sol";

contract CompoundStaking is IERC20 {
    string public name;
    string public symbol;

    address public owner;
    
    bool public revertFlag;
    uint public totalShares;
    uint public potentiallyMinted;
    uint public lastRewardBlock;
    uint public requiredBalance;
    uint public blocksInYear;
    uint public apyUp;
    uint public apyDown;
    uint public decimals;
    address[] public lpAdmins;

    struct UserInfo {
        uint share;
        uint tokenAtLastUserAction;
    }

    IERC20 public immutable token;
    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => uint)) public allowances;

    constructor(
        IERC20 _token,
        uint _blocksInYear,
        string memory _name,
        string memory _symbol,
        uint _apyUp,
        uint _apyDown,
        address[] memory admins
    ) {
        owner = msg.sender;
        token = _token;
        blocksInYear = _blocksInYear;
        lastRewardBlock = block.number;
        decimals = token.decimals();
        name = _name;
        symbol = _symbol;
        apyUp = _apyUp;
        apyDown = _apyDown;
        lpAdmins = admins;
    }

    modifier notReverted() {
        require(!revertFlag, "Compound: reverted flag on.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Compound: permitted to owner only.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender==owner || AddressArrayLib.indexOf(lpAdmins, msg.sender) != -1, 
            "Compound: permitted to admins only.");
        _;
    }

    event RevertFlag(bool flag);
    event SetOwner(address oldOwner, address newOwner);
    event SetApy(uint oldDown, uint oldUp, uint newDown, uint newUp);
    event SetBlockInYear(uint oldBlocksInYear, uint newBlocksInYear);
    
    function totalSupply() public view returns (uint256) {
        uint tokenPerBlock = apyUp * requiredBalance / apyDown / blocksInYear;
        uint delta = block.number - lastRewardBlock;
        uint potentialMint = delta * tokenPerBlock;
        return requiredBalance+potentialMint;
    }

    function balanceOf(address _user) public view returns(uint) {
        if(totalShares <= 0) return 0;
        return userInfo[_user].share * totalSupply() / totalShares;
    }

    function shareToBalance(uint _share) public view returns(uint) { 
        return _share * totalSupply() / totalShares;
    }

    function balanceToShare(uint _balance) public view returns(uint) { 
        return _balance * totalShares / totalSupply();
    }

    function setAdmins(address[] memory admins) public onlyOwner {
        for(uint i = 0; i < admins.length; i++) {
            lpAdmins.push(admins[i]);
        }
    }

    function removeAdmins(address[] memory admins) public onlyOwner {
        for(uint i = 0; i < admins.length; i++) {
            AddressArrayLib.removeItem(lpAdmins, admins[i]);
        }
    }

    function setApy(uint _apyUp, uint _apyDown) public onlyAdmin {
        updateRewardPool();
        uint oldDown = apyDown;
        uint oldUp = apyUp;
        apyUp = _apyUp;
        apyDown = _apyDown;
        emit SetApy(oldDown, oldUp, _apyDown, _apyUp);
    }

    function setBlocksInYear(uint _blocksInYear) public onlyAdmin {
        updateRewardPool();
        uint oldBlocksInYear = blocksInYear;
        blocksInYear = _blocksInYear;
        emit SetBlockInYear(oldBlocksInYear, _blocksInYear);
    }

    function toggleRevert() public onlyOwner {
        revertFlag = !revertFlag;
    }

    function withdrawToken(IERC20 _token, address _to, uint _amount) public onlyOwner {
            require(_token.transfer(_to,_amount));
    }

    function transferOwnership(address _owner) public onlyOwner {
        address oldOwner = owner;
        owner = _owner;
        emit SetOwner(oldOwner, _owner);
    }

    function allowance(address _owner, address spender) external view returns (uint256) {
        return allowances[_owner][spender];
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function approve(address spender, uint amount) public notReverted virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint transferShareUnit = balanceToShare(amount);
        require(userInfo[sender].share >= transferShareUnit, "ERC20: transfer amount exceeds balance");
        userInfo[sender].share -= transferShareUnit;
        userInfo[recipient].share += transferShareUnit;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public notReverted virtual override returns (bool) {
        updateRewardPool();
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferShare(
        address to,
        uint share
    ) public notReverted {
        require(userInfo[msg.sender].share >= share, "insufficent balance");
        userInfo[msg.sender].share -= share;
        userInfo[to].share += share;
        userInfo[msg.sender].tokenAtLastUserAction = balanceOf(msg.sender);
        userInfo[to].tokenAtLastUserAction = balanceOf(to);
    }   

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public notReverted virtual override returns (bool) {
        updateRewardPool();
        _transfer(spender, recipient, amount);
        uint256 currentAllowance = allowances[spender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(spender, msg.sender, currentAllowance - amount);
        return true;
    }

    function updateRewardPool() public notReverted {
        uint tokenPerBlock = apyUp * requiredBalance / apyDown / blocksInYear;
        uint delta = block.number - lastRewardBlock;
        uint potentialMint = delta * tokenPerBlock;
        potentiallyMinted += potentialMint;
        requiredBalance += potentialMint;
        lastRewardBlock = block.number;
    }

    function mint(uint _amount, address _to) external notReverted {
        updateRewardPool();
        require(_amount > 0, "Compound: Nothing to deposit");
        require(token.transferFrom(msg.sender,address(this),_amount),"");
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = _amount * totalShares / requiredBalance;
        } else {
            currentShares = _amount;
        }
        totalShares += currentShares;
        requiredBalance += _amount;
        UserInfo storage user = userInfo[_to];
        user.share += currentShares;
        user.tokenAtLastUserAction = balanceOf(_to);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _to, uint256 _share) public notReverted {
        updateRewardPool();
        require(_share > 0, "Compound: Nothing to burn");

        UserInfo storage user = userInfo[msg.sender];
        require(_share <= user.share, "Compound: Withdraw amount exceeds balance");
        uint256 currentAmount = requiredBalance * _share / totalShares;
        user.share -= _share;
        totalShares -= _share;
        requiredBalance -= currentAmount;
        user.tokenAtLastUserAction = balanceOf(msg.sender);
        require(token.transfer(_to,currentAmount),"Compound: Not enough token to transfer");
        emit Transfer(_to, address(0), currentAmount);
    }
}