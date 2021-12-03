/***
 *
 *     ____ ____ ____ ____ ____ ____ _________ ____ ____ ____ ____ 
 *    ||K |||a |||w |||a |||i |||i |||       |||C |||a |||t |||s ||
 *    ||__|||__|||__|||__|||__|||__|||_______|||__|||__|||__|||__||
 *    |/__\|/__\|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|
 *
 * 
 *  Project: Kawaii Cats
 *  Website: https://kawaiicats.xyz/
 *  Contract: PURR token
 *  
 *  Description: PURR is the token on the project. PURR is minted by all cat NFTs.
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IKawaiiCatsNFT.sol"; 
import "./ICatFight.sol"; 

/**
 * @dev Implementation of the {IERC20} interface. 
 *
 */
contract PURRtoken is Context, IERC20Metadata, Ownable { 
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint16 => uint256) private _lastHarvest;
    mapping (uint16 => uint256) public totalTokensWon;
    
    mapping (uint16 => uint16) public nftBattleCount;
    mapping (uint16 => uint256) public nftBattleEndTime;
    mapping (address => uint256) public buffEndTime;

    mapping (uint16 => uint256) public tokensFromBattle;
  
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _nftContractAddress;
    address private _uniqueItemsContract;
    address private _catFightContract;
    address private _additionalContract;
    address private _pool;
  

    uint256 public PURR_PER_DAY = 500000000000000000; //0.5 PURR/day ratio
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public capLP = 20; //max 20 extra battle points for LP providers
    uint256 public BUFF_BONUS = 20; //20 extra battle points
    uint256 public BUFF_BONUS_CLAIM = 110; //110% increase of PURR claiming
    uint256 public WIN_REWARD =  500000000000000000; //0.5 PURR/win
    uint256 public LOSE_REWARD = 100000000000000000; //0.1 PURR/lose
    uint256 public BUFF_COST = 2000000000000000000; //2 PURR
    bool public gamePaused; 

    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    
    event BattleCompleted(uint16 indexed _fromId, uint16 indexed _toId, bool _outcome);
     
    /**
     * @dev Sets the values for {name}, {symbol} and {owner}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply_;
        _balances[msg.sender] = initialSupply_;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, initialSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Show total supply to external contracts.
     */
    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    } 

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Get balance to external contracts.
     */
    function getBalanceOf(address account) external view returns (uint256) {
        return _balances[account];
    } 

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        //uint256 currentAllowance = _allowances[sender][_msgSender()];
        //require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        //_approve(sender, _msgSender(), currentAllowance - amount);
       
        if ((msg.sender != _nftContractAddress) && (msg.sender != _uniqueItemsContract) && (msg.sender != _catFightContract) && (msg.sender != _additionalContract)) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
     
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
       
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
 
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    /**
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Set NFT address
     */
    function setNFTContractAddress(address contractAddress) public onlyOwner{
        _nftContractAddress = contractAddress;
    }
    
    
    /**
     * @dev Set unique items contract address
     */
    function setUniqueItemsContractAddress (address contractAddress) public onlyOwner{
        _uniqueItemsContract = contractAddress;
    }
    
    /**
     * @dev Set cat fight contract address
     */
    function setCatFightContractAddress (address contractAddress) public onlyOwner{
        _catFightContract = contractAddress;
    }
    
    /**
     * @dev Set additional contract address
     */
    function setAdditionalContractAddress (address contractAddress) public onlyOwner{
        _additionalContract = contractAddress;
    }
    
    /**
     * @dev Mints daily tokens assigned to a NFT. Returns the minted quantity.
     */
    function claimTokens(uint16[] memory tokenIds) public returns (uint256) {
        uint256 totalHarvestQty = 0;
        require(!gamePaused, "Game paused by admin");
        
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IKawaiiCatsNFT(_nftContractAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IKawaiiCatsNFT(_nftContractAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            
            uint256 harvestQty = tokensToClaim(tokenIndex); 
            if (harvestQty != 0) {
                totalTokensWon[tokenIndex] = totalTokensWon[tokenIndex].add(harvestQty);
                totalHarvestQty = totalHarvestQty.add(harvestQty);
                _lastHarvest[tokenIndex] = block.timestamp;
                tokensFromBattle[tokenIndex] = 0;
            }
        }

        require(totalHarvestQty != 0, "Nothing to harvest");
        _mint(msg.sender, totalHarvestQty); 
        return totalHarvestQty;
    }
   
    /**
     * @dev Measures daily tokens assigned to a NFT, that are ready to be harvested.
     */
    function tokensToClaim(uint16 tokenIndex) public view returns (uint256) {
        require(IKawaiiCatsNFT(_nftContractAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IKawaiiCatsNFT(_nftContractAddress).totalSupply(), "NFT has not been minted yet");
        uint256 lastHarvested;
        if (_lastHarvest[tokenIndex]==0)
            lastHarvested = IKawaiiCatsNFT(_nftContractAddress).getBirthday(tokenIndex); 
        else
            lastHarvested = _lastHarvest[tokenIndex];
            
        uint _rarityMultiplier = 1;    
        if (IKawaiiCatsNFT(_nftContractAddress).getRarity(tokenIndex) == 3)  
            _rarityMultiplier = 2;
        else if (IKawaiiCatsNFT(_nftContractAddress).getRarity(tokenIndex) == 2)  
            _rarityMultiplier = 5;    
        else if (IKawaiiCatsNFT(_nftContractAddress).getRarity(tokenIndex) == 1)  
            _rarityMultiplier = 10; 
            
        uint bonusMultiplier = 100;    
        //buff bonus
        if(buffEndTime[msg.sender] >= block.timestamp)
            bonusMultiplier = BUFF_BONUS_CLAIM;       
            
        uint256 totalAccumulated = (block.timestamp).sub(lastHarvested).mul(PURR_PER_DAY).div(SECONDS_PER_DAY).mul(_rarityMultiplier).mul(bonusMultiplier).div(100);
        return totalAccumulated + tokensFromBattle[tokenIndex];
    }
    
    /**
     * @dev Measures daily tokens assigned to a NFT array that are ready to be harvested.
     */
    function tokensArrayToClaim(uint16[] memory tokenIds) public view returns (uint256) {
        uint256 totalSum;
        for (uint i = 0; i < tokenIds.length; i++)
           totalSum = totalSum.add(tokensToClaim(tokenIds[i]));
    
        return totalSum;
    }
    
    /**
     * @dev Modifies daily reward
     */
    function modifyDailyReward(uint _dailyReward) public onlyOwner {
        PURR_PER_DAY = _dailyReward;
    }
    
    /**
     * @dev Modifies buff bonus claiming
     */
    function modifyBuffBonusClaim(uint _newBonus) public onlyOwner {
        BUFF_BONUS_CLAIM = _newBonus;
    }
    
    /**
     * @dev Modifies buff bonus claiming
     */
    function modifyBuffBonus(uint _newBonus) public onlyOwner {
        BUFF_BONUS = _newBonus;
    }
    
    /**
     * @dev Set LP address
     */
    function setLP(address LPAddress) public onlyOwner{
        _pool = LPAddress;
    }
    
    /**
     * @dev Check LP tokens
     */
    function lpTokens(address _playerAddress) public view returns (uint) {
        return IERC20(_pool).balanceOf(_playerAddress).div(1000000000000000000);
    }
    
    /**
     * @dev Buffs and NFT
     */
    function getBuff() public {
        require(balanceOf(msg.sender) >= BUFF_COST, "Not enough PURR");
        require(buffEndTime[msg.sender] <= block.timestamp, "Still under buff");
        increaseAllowance(address(this), BUFF_COST);
        burn(BUFF_COST);
        buffEndTime[msg.sender] = block.timestamp.add(SECONDS_PER_DAY);
    }
    
    /**
     * @dev Prepare battle
     */
    function prepareBattle(uint16 _fromId, uint16 _toId) internal returns(bool){
        
        //LP bonus 
        uint _LPsFrom = lpTokens(IKawaiiCatsNFT(_nftContractAddress).ownerOf(_fromId));
        uint _LPsTo = lpTokens(IKawaiiCatsNFT(_nftContractAddress).ownerOf(_toId));
        if (_LPsFrom > capLP)
            _LPsFrom = capLP;
        if (_LPsTo > capLP)
            _LPsTo = capLP;
        
        //buff bonus    
        uint _buffBonusFrom;    
        uint _buffBonusTo;    
        if(buffEndTime[msg.sender] >= block.timestamp)
            _buffBonusFrom = BUFF_BONUS;
        if(buffEndTime[IKawaiiCatsNFT(_nftContractAddress).ownerOf(_toId)] >= block.timestamp)
            _buffBonusTo = BUFF_BONUS;    
        
        if ((ICatFight(_catFightContract).calculateBattlePoints(_fromId) + _LPsFrom.mul(5) + _buffBonusFrom) >= (ICatFight(_catFightContract).calculateBattlePoints(_toId) + _LPsTo.mul(5) + _buffBonusTo)) 
        {
            ICatFight(_catFightContract).increaseWins(_fromId);
            ICatFight(_catFightContract).increaseLosses(_toId);
            tokensFromBattle[_fromId] = tokensFromBattle[_fromId] + WIN_REWARD; 
            //tokensFromBattle[_toId] = tokensFromBattle[_toId] + LOSE_REWARD; 
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(WIN_REWARD));
            //totalTokensWon[_toId] = (totalTokensWon[_toId].add(LOSE_REWARD));
            return true;
        } else {
            ICatFight(_catFightContract).increaseWins(_toId);
            ICatFight(_catFightContract).increaseLosses(_fromId);
            tokensFromBattle[_fromId] = tokensFromBattle[_fromId] + LOSE_REWARD; 
            //tokensFromBattle[_toId] = tokensFromBattle[_toId] + WIN_REWARD; 
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(LOSE_REWARD));
            //totalTokensWon[_toId] = (totalTokensWon[_toId].add(WIN_REWARD));
            return false;
        }
    } 
    
    /**
     * @dev Returns a random NFT id, different from the _Id input.
     */
    function getRandomNFTId(uint16 _Id, uint nonce) internal view returns (uint16) {
        require(_Id < IKawaiiCatsNFT(_nftContractAddress).totalSupply());
        bool success;
        uint randomNFTId;
        uint _seed;
        
        for(uint16 i=0;i<50;i++)
        {
            randomNFTId = uint(keccak256(abi.encodePacked(block.timestamp, _seed, nonce))).mod(IKawaiiCatsNFT(_nftContractAddress).totalSupply());
            if(randomNFTId == _Id)
            {
                _seed = _seed.add(1);
            }
            else
            {
                success = true;
                break;
            }
        }
        
        require(success, "Try again");
        return uint16(randomNFTId);
    }
    
    /**
     * @dev Callable battle function.
     */
    function battle(uint16 _fromId, uint nonce) public returns (bool) {
        require(msg.sender == IKawaiiCatsNFT(_nftContractAddress).ownerOf(_fromId));
        require(!gamePaused, "Game paused by admin");
        
        if(nftBattleEndTime[_fromId] >= block.timestamp )
        {
            require(nftBattleCount[_fromId] <  ICatFight(_catFightContract).getStamina(_fromId), "Enough battles for today");
            nftBattleCount[_fromId] = nftBattleCount[_fromId].add(1);
        }
        else
        {
            nftBattleEndTime[_fromId] = block.timestamp.add(SECONDS_PER_DAY);
            nftBattleCount[_fromId] = 1;
        }   

        uint16 _toId = getRandomNFTId(_fromId, nonce);
        bool battleResult = prepareBattle(_fromId, _toId);
        emit BattleCompleted(_fromId, _toId, battleResult);
        return battleResult;
    }
    
    /**
     * @dev Optimized callable battle function for multi-battle.
     */
    function battleMulti(uint16 _fromId, uint nonce) internal returns (bool) {
        require(!gamePaused, "Game paused by admin");
        
        if(nftBattleEndTime[_fromId] >= block.timestamp )
        {
            require(nftBattleCount[_fromId] <  ICatFight(_catFightContract).getStamina(_fromId), "Enough battles for today");
            nftBattleCount[_fromId] = nftBattleCount[_fromId].add(1);
        }
        else
        {
            nftBattleEndTime[_fromId] = block.timestamp.add(SECONDS_PER_DAY);
            nftBattleCount[_fromId] = 1;
        }   

        uint16 _toId = getRandomNFTId(_fromId, nonce);
        bool battleResult = prepareBattle(_fromId, _toId);
        emit BattleCompleted(_fromId, _toId, battleResult);
        return battleResult;
    }
    
    /**
     * @dev Optimized multi-battle.
     */
    function battleAll(uint16[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IKawaiiCatsNFT(_nftContractAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IKawaiiCatsNFT(_nftContractAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            
            if(nftBattleEndTime[tokenIndex] >= block.timestamp )
            {   
                if(nftBattleCount[tokenIndex] <  ICatFight(_catFightContract).getStamina(tokenIndex))
                {
                    uint difference = ICatFight(_catFightContract).getStamina(tokenIndex).sub(nftBattleCount[tokenIndex]);
                    for (uint k = 0; k < difference; k++)
                    {    
                        battleMulti(tokenIndex, k);
                    }
                }
            }
            else
            {
                for (uint k = 0; k < ICatFight(_catFightContract).getStamina(tokenIndex); k++)
                {    
                    battleMulti(tokenIndex, k);
                }
            }
        }
    }
    
    /**
     * @dev Modifies win reward
     */
    function modifyBattleReward(uint _winReward, uint _loseReward) public onlyOwner {
        WIN_REWARD = _winReward;
        LOSE_REWARD = _loseReward;
    }
    
    /**
     * @dev Modifies LP cap
     */
    function modifyLPCap(uint _newCapLP) public onlyOwner {
        capLP = _newCapLP;
    }
    
    
    /**
     * @dev Pauses game for future updates
     */
    function switchGamePaused() public onlyOwner {
        if (gamePaused == false){
            gamePaused = true;
        }
        else{
            gamePaused = false;  
        }
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}