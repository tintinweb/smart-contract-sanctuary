// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IFA.sol"; 
import "./IFAAD.sol"; 
 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 */
contract AWToken is Context, IERC20Metadata, Ownable { 
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint16 => uint256) private _lastHarvest;
    
    mapping (uint16 => uint16) public nftBattleCount;
    mapping (uint16 => uint256) public nftBattleEndTime;
    mapping (uint16 => uint256) public totalTokensWon;

    
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _nftAddress;
    address private _nftAddonsAddress;
   
     
     
    uint256 public WIN_REWARD = 1000000000000000000;
    uint256 public LOSE_REWARD = 100000000000000000;
    uint256 public TOKENS_PER_DAY = 1000000000000000000;
    
    uint public constant SECONDS_PER_DAY = 86400;
    bool public gamePaused; 
    bool public battleWithAddons;
    
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
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        if (msg.sender != _nftAddress) {
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
        require(!gamePaused, "Game paused by admin");

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
        require(!gamePaused, "Game paused by admin");
         
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
        require(!gamePaused, "Game paused by admin");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Only callable once, right after deployment.
     */
    function setNFTContractAddress(address nftAddress) public {
        require(_nftAddress == address(0), "Already set");
        
        _nftAddress = nftAddress;
    }
    
    /**
     * @dev Only callable once, right after deployment.
     */
    function setNFTAddonsContractAddress(address nftAddonsAddress) public {
        require(_nftAddonsAddress == address(0), "Already set");
        
        _nftAddonsAddress = nftAddonsAddress;
    }
    
    /**
     * @dev Logic of the battle between 2 NFTs. _fromId is the initiator of the battle.
     *      Returns true if the initiator wins, false otherwise.
     */
    function battleFA(uint16 _fromId, uint16 _toId) internal returns(bool){
        
        if (IFA(_nftAddress).battlePoints(_fromId) >= IFA(_nftAddress).battlePoints(_toId)) {
            IFA(_nftAddress)._increaseWins(_fromId);
            IFA(_nftAddress)._increaseLosses(_toId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), WIN_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), LOSE_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(WIN_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(LOSE_REWARD));
            return true;
        } else {
            IFA(_nftAddress)._increaseWins(_toId);
            IFA(_nftAddress)._increaseLosses(_fromId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), LOSE_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), WIN_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(LOSE_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(WIN_REWARD));
            return false;
        }
    } 
    
    /**
     * @dev Logic of the battle between 2 NFTs with addons. _fromId is the initiator of the battle.
     *      Returns true if the initiator wins, false otherwise.
     */
    function newBattleFA(uint16 _fromId, uint16 _toId) internal returns(bool){
        
        if (IFAAD(_nftAddonsAddress).newBattlePoints(_fromId, _toId) >= IFAAD(_nftAddonsAddress).newBattlePoints(_toId, _fromId)) {
            IFA(_nftAddress)._increaseWins(_fromId);
            IFA(_nftAddress)._increaseLosses(_toId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), WIN_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), LOSE_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(WIN_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(LOSE_REWARD));
            return true;
        } else {
            IFA(_nftAddress)._increaseWins(_toId);
            IFA(_nftAddress)._increaseLosses(_fromId);
            _mint(IFA(_nftAddress).ownerOf(_fromId), LOSE_REWARD); 
            _mint(IFA(_nftAddress).ownerOf(_toId), WIN_REWARD);
            totalTokensWon[_fromId] = (totalTokensWon[_fromId].add(LOSE_REWARD));
            totalTokensWon[_toId] = (totalTokensWon[_toId].add(WIN_REWARD));
            return false;
        }
    } 
    
    /**
     * @dev Returns a random NFT id, different from the _Id input.
     */
    function getRandomNFTId(uint16 _Id, uint nonce) internal view returns (uint16) {
        require(_Id < IFA(_nftAddress).totalSupply());
        bool success;
        uint randomNFTId;
        uint _seed;
        
        for(uint16 i=0;i<50;i++)
        {
            randomNFTId = uint(keccak256(abi.encodePacked(block.timestamp, _seed, nonce))).mod(IFA(_nftAddress).totalSupply());
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
    function battle(uint16 _fromId, uint nonce) public {
        require(msg.sender == IFA(_nftAddress).ownerOf(_fromId));
        require(!IFA(_nftAddress).isBanned(_fromId),"This NFT is banned");
        require(!gamePaused, "Game paused by admin");
        
        if(nftBattleEndTime[_fromId] >= block.timestamp )
        {
            require(nftBattleCount[_fromId] <  IFA(_nftAddress).getStamina(_fromId), "Enough battles for today");
            nftBattleCount[_fromId] = nftBattleCount[_fromId].add(1);
        }
        else
        {
            nftBattleEndTime[_fromId] = block.timestamp.add(SECONDS_PER_DAY);
            nftBattleCount[_fromId] = 1;
        }   

        uint16 _toId = getRandomNFTId(_fromId, nonce);
        bool battleResult;
        if (battleWithAddons)
            battleResult = newBattleFA(_fromId, _toId);
        else
            battleResult = battleFA(_fromId, _toId); 
        emit BattleCompleted(_fromId, _toId, battleResult);
    }
    
    
    
    /**
     * @dev Mints daily tokens assigned to a NFT. Returns the minted quantity.
     */
    function battleAll(uint16[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IFA(_nftAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            require(!IFA(_nftAddress).isBanned(tokenIndex),"This NFT is banned");
            
            if(nftBattleEndTime[tokenIndex] >= block.timestamp )
            {   
                if(nftBattleCount[tokenIndex] <  IFA(_nftAddress).getStamina(tokenIndex))
                {
                    uint difference = IFA(_nftAddress).getStamina(tokenIndex).sub(nftBattleCount[tokenIndex]);
                    for (uint k = 0; k < difference; k++)
                        battle(tokenIndex, k);
                }
            }
            else
            {
                for (uint k = 0; k < IFA(_nftAddress).getStamina(tokenIndex); k++)
                        battle(tokenIndex, k);
            }
        }
    }
    
    /**
     * @dev Mints daily tokens assigned to a NFT. Returns the minted quantity.
     */
    function harvestTokens(uint16[] memory tokenIds) public returns (uint256) {
        require(!gamePaused, "Game paused by admin");
        uint256 totalHarvestQty = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            // Sanity check for non-minted index
            require(tokenIds[i] < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
            // Duplicate token index check
            for (uint j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token index");
            }

            uint16 tokenIndex = tokenIds[i];
            require(IFA(_nftAddress).ownerOf(tokenIndex) == msg.sender, "Sender is not the owner");
            require(!IFA(_nftAddress).isBanned(tokenIndex),"This NFT is banned");

            uint256 harvestQty = tokensToHarvest(tokenIndex); 
            if (harvestQty != 0) {
                totalTokensWon[tokenIndex] = totalTokensWon[tokenIndex].add(harvestQty);
                totalHarvestQty = totalHarvestQty.add(harvestQty);
                _lastHarvest[tokenIndex] = block.timestamp;
            }
        }

        require(totalHarvestQty != 0, "Nothing to harvest");
        _mint(msg.sender, totalHarvestQty); 
        return totalHarvestQty;
    }
   
    /**
     * @dev Measures daily tokens assigned to a NFT, that are ready to be harvested.
     */
    function tokensToHarvest(uint16 tokenIndex) public view returns (uint256) {
        require(IFA(_nftAddress).ownerOf(tokenIndex) != address(0), "Owner cannot be 0 address");
        require(tokenIndex < IFA(_nftAddress).totalSupply(), "NFT has not been minted yet");
        uint256 lastHarvested;
        if (_lastHarvest[tokenIndex]==0)
            lastHarvested = IFA(_nftAddress).getBirthday(tokenIndex); 
        else
            lastHarvested = _lastHarvest[tokenIndex];
        
        uint256 totalAccumulated = (block.timestamp).sub(lastHarvested).mul(TOKENS_PER_DAY).div(SECONDS_PER_DAY);
        return totalAccumulated;
    }
    
     /**
     * @dev Measures daily tokens assigned to a NFT array that are ready to be harvested.
     */
    function tokensArrayToHarvest(uint16[] memory tokenIds) public view returns (uint256) {
        uint256 totalSum;
        for (uint i = 0; i < tokenIds.length; i++)
           totalSum = totalSum.add(tokensToHarvest(tokenIds[i]));
    
        return totalSum;
    }
    
    /**
     * @dev Modifies win reward
     */
    function modifyWinReward(uint _winReward) public onlyOwner {
        WIN_REWARD = _winReward;
    }
    
    /**
     * @dev Modifies lose reward
     */
    function modifyLoseReward(uint _loseReward) public onlyOwner {
        LOSE_REWARD = _loseReward;
    }
    
    /**
     * @dev Modifies daily reward
     */
    function modifyDailyReward(uint _dailyReward) public onlyOwner {
        TOKENS_PER_DAY = _dailyReward;
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
     * @dev Takes addons into account
     */
    function switchBattleWithAddons() public onlyOwner {
        if (battleWithAddons == false){
            battleWithAddons = true;
        }
        else{
            battleWithAddons = false;  
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