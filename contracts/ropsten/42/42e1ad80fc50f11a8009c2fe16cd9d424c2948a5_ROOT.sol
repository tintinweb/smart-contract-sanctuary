/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) private _balances;
    mapping(address => bool) public feeExcludedAddress;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint256 => uint256) lastReward;

    uint256 private _totalSupply;
    
    // Daily Rewards Distributions Start from
    uint256 private rewardStartDate;
    bool public dailyReward = false;
    uint256 public rewardAmount = 10 ether;
    // ends in a month;
    

    string private _name;
    string private _symbol;
    uint private _decimals = 18;
    uint private _lockTime;
    address public _Owner;
    address public _previousOwner;
    address public _fundAddress;
    address public liquidityPair;
    uint public teamFee = 300; //0.2% divisor 100
    uint public burnFee = 300; //0.2% divisor 100
    bool public sellLimiter; //by default false
    uint public sellLimit = 50000 * 10 ** 18; //sell limit if sellLimiter is true
    
    // // address[] public holders;
    // // mapping (address => bool) public holder;
    INFT public NFTContract;
    
    uint256 public _maxTxAmount = 5000000 * 10**18;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event claimedDailyReward(uint256 tokenID, address claimer, uint256 timestamp);

    constructor (string memory _nm, string memory _sym, INFT _NFTContract) public {
        _name = _nm;
        _symbol = _sym;
        _Owner = msg.sender;
        rewardStartDate = block.timestamp;
        NFTContract = _NFTContract;
        feeExcludedAddress[msg.sender] = true;
        _fundAddress = address(0x43a3f032E34467e8f692244461CA1b422f9af230);
    }
    
    modifier onlyOwner{
        require(msg.sender == _Owner, 'Only Owner Can Call This Function');
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function calculateTeamBurn(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(teamFee+burnFee).div(
            10**4
        );
    }
    
    function calculateTeamFee(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(teamFee).div(
            10**4
        );
    }
    
    function setTeamFee(uint Tfee) public onlyOwner{
        require(Tfee < 1500," Fee can't exceed to 15%");
        teamFee = Tfee;
    }
    
    function setBurnFee(uint Tfee) public onlyOwner{
        require(Tfee < 1500," Fee can't exceed to 15%");
        burnFee = Tfee;
    }
    
    function toggleSellLimit() external onlyOwner() {
        sellLimiter = !sellLimiter;
    }
    
    function stopReward() external onlyOwner() {
        require(dailyReward, "Daily Reward Already Stopped");
        dailyReward = false;
    }
    
    function startReward() public onlyOwner{
        require(!dailyReward, "Daily Reward Already Running");
        dailyReward = true;
        rewardStartDate = block.timestamp;
    }
    
    function changeRewardAmount(uint256 _amount) public onlyOwner{
        rewardAmount = _amount;
    }
    
    function setLiquidityPairAddress(address liquidityPairAddress) public onlyOwner{
        liquidityPair = liquidityPairAddress;
    }
    
    function changeSellLimit(uint256 _sellLimit) public onlyOwner{
        sellLimit = _sellLimit;
    }
    
    function changeMaxtx(uint256 _maxtx) public onlyOwner{
        _maxTxAmount = _maxtx;
    }
    
    function changeFundAddress(address Taddress) public onlyOwner{
        _fundAddress = Taddress;
    }
    
    function addExcludedAddress(address excludedA) public onlyOwner{
        feeExcludedAddress[excludedA] = true;
    }
    
    function removeExcludedAddress(address excludedA) public onlyOwner{
        feeExcludedAddress[excludedA] = false;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_Owner, newOwner);
        _Owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _Owner;
        _Owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_Owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_Owner, _previousOwner);
        _Owner = _previousOwner;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        require(receivers.length != 0, 'Cannot Proccess Null Transaction');
        require(receivers.length == amounts.length, 'Address and Amount array length must be same');
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(feeExcludedAddress[recipient] || feeExcludedAddress[_msgSender()]){
            _transferExcluded(_msgSender(), recipient, amount);
        }else{
            _transfer(_msgSender(), recipient, amount);    
        }
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(feeExcludedAddress[recipient] || feeExcludedAddress[sender]){
            _transferExcluded(sender, recipient, amount);
        }else{
            _transfer(sender, recipient, amount);
        }
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transferExcluded(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(sender != _Owner && recipient != _Owner)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
        if(recipient == liquidityPair && balanceOf(liquidityPair) > 0 && sellLimiter){
            require(amount < sellLimit, 'Cannot sell more than sellLimit');
        }

        // if(holder[recipient] == false){
        //     holder[recipient] = true;
        //     holders.push(recipient);
        // }
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _transfer( address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(sender != _Owner && recipient != _Owner)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(recipient == liquidityPair && balanceOf(liquidityPair) > 0 && sellLimiter){
            require(amount < sellLimit, 'Cannot sell more than sellLimit');
        }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        uint256 tokenToTransfer = amount.sub(calculateTeamBurn(amount));
        _balances[recipient] += tokenToTransfer;
        _balances[_fundAddress] += calculateTeamFee(amount);
        
        
        emit Transfer(sender, recipient, tokenToTransfer);
        
        // if(recipient == liquidityPair && balanceOf(liquidityPair) > 0 && sellLimiter){
        //     require(amount < sellLimit, 'Cannot sell more than sellLimit');
        // }
        
        
        // uint256 senderBalance = _balances[sender];
        // require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        // _balances[sender] = senderBalance - amount;
        // _balances[recipient] += (amount * 93) / 100;
        // _balances[_fundAddress] += (amount * 2) / 100;
        
        // _burn((amount * 3) / 100);
        
        // uint256 tokenToTransfer = (amount * 2) / 100;
        
        // if(holder[recipient] == false){
        //     holder[recipient] = true;
        //     holders.push(recipient);
        // }
        
        // // Redistribution(tokenToTransfer);
        // total1 = totalSupply() - balanceOf(_fundAddress);
        // // a1 = total / tokenToTransfer;
        // for(uint i=0; i<holders.length; i++){
        //     address addr = holders[i];
        //     uint256 amount1 = (balanceOf(addr).mul(tokenToTransfer)).div(total1);
        //     // holders[i] = _balances[addr]
        //     _balances[addr] += amount1;
        //     amount123.push(addr);
        //     a1 += balanceOf(addr);
        // }
        // emit Transfer(sender, recipient, tokenToTransfer);
    }
    
    uint256 public total1;
    uint256 public a1;
    address[] public amount123;

    // function Redistribution(uint256 tokenToTransfer) internal  {
    //     total1 = totalSupply() - balanceOf(_fundAddress);
    //     // a1 = total / tokenToTransfer;
    //     for(uint i=0; i<holders.length; i++){
    //         address addr = holders[i];
    //         uint256 amount = (balanceOf(addr) / total1) * tokenToTransfer;
    //         // holders[i] = _balances[addr]
    //         _balances[addr] += amount;
    //         a1 += balanceOf(addr);
    //     }
    // }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function addSupply(uint256 amount) public onlyOwner{
        _mint(msg.sender, amount);
    }
    
    function checkDailyReward(uint256 tokenID) public view returns (uint256){
        uint256 lastdate = (lastReward[tokenID] > rewardStartDate) ? lastReward[tokenID] : rewardStartDate;
        uint256 rewardDays = (block.timestamp - lastdate).div(1 days);
        return rewardDays.mul(rewardAmount);
    }
    
    function claimDailyReward(uint256 tokenID) public {
        require(dailyReward," Daily Rewards Are Stopped ");
        require(NFTContract.ownerOf(tokenID) == msg.sender, "You aren't own this NFT token");
        require(checkDailyReward(tokenID) > 0, "There is no claimable reward");
        _mint(msg.sender, checkDailyReward(tokenID));
        lastReward[tokenID] = block.timestamp;
        emit claimedDailyReward(tokenID, msg.sender, block.timestamp);
    }
    
    function bulkClaimRewards(uint256[] memory tokenIDs) public {
        require(dailyReward," Daily Rewards Are Stopped ");
        uint256 total;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(NFTContract.ownerOf(tokenIDs[i]) == msg.sender, "You aren't own this NFT token");
            total += checkDailyReward(tokenIDs[i]);
            if(checkDailyReward(tokenIDs[i]) > 0){
                lastReward[tokenIDs[i]] = block.timestamp;
            }
        }
        require(total > 0, "There is no claimable reward");
        _mint(msg.sender, total);
    }

    function _burn(uint256 amount) public virtual {
        require(_balances[msg.sender] >= amount,'insufficient balance!');

        _beforeTokenTransfer(msg.sender, address(0x000000000000000000000000000000000000dEaD), amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0x000000000000000000000000000000000000dEaD), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function NFTBalance(address __address) public view returns(uint256) {
        return NFTContract.balanceOf(__address);
    }

    function NFTOwner(uint256 __id) public view returns(address ) {
        return NFTContract.ownerOf(__id);
    }

    function NFTWallet(address __address) public view returns(uint256[] memory) {
        return NFTContract.walletOfOwner(__address);
    }
    
    struct challenge{
        uint256 id;
        string des;
        uint256 roots;
        uint256 nfts;
        bool status;
    }   
    
    uint256 public challengeCount = 0;
    mapping (uint => challenge) public Challenges;
    mapping(uint => mapping(address => bool)) public entry;
    
    function startChallnge(string  memory _des, uint256 _roots, uint256 _nfts) public onlyOwner{
        Challenges[challengeCount+1] = challenge(challengeCount+1, _des, _roots, _nfts, true);
        challengeCount++;
    }
    
    function enterChallenge(uint256 _id) public {
        require(_id == Challenges[_id].id && _id != 0, "Invalid ID");
        require(Challenges[_id].status == true, "Challenge ended");
        require(entry[_id][msg.sender] != true, "You are already inrolled in this challenge");
        require(Challenges[_id].nfts <= NFTContract.balanceOf(msg.sender), "You own less amount of BearX than reequired");
        require(Challenges[_id].roots <= balanceOf(msg.sender), "You own less amount of ROOT than required");
        _burn(Challenges[_id].roots);
        entry[_id][msg.sender] = true;
    }
    
    function toggleChallengeStatus(uint256 _id) public onlyOwner {
        require(_id == Challenges[_id].id && _id != 0, "Invalid ID");
        Challenges[_id].status = !Challenges[_id].status;
    }    
    
    
    function u_contract(address _contarct) public onlyOwner {
        require(_contarct != address(0), "Invalid address");
        NFTContract = INFT(_contarct);
    }    
    
    
}


contract ROOT is ERC20 {
    constructor(INFT NFTContract) public ERC20("ROOT", "ROOT", NFTContract) {
        _mint(msg.sender, 4500 ether); // 
        // holder[msg.sender] = true;
        // holders.push(msg.sender);
    }
}