// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Curve/interfaces/ICurve.sol";

contract BrincToken is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyTaxRateChanged(uint256 oldRate, uint256 newRate);
    event SellTaxRateChanged(uint256 oldRate, uint256 newRate);
    event BuyTaxScaleChanged(uint256 oldScale, uint256 newScale);
    event SellTaxScaleChanged(uint256 oldScale, uint256 newScale);

    IERC20 private _reserveAsset;
    uint32 private _fixedReserveRatio;
    uint256 private _buyTaxRate;
    uint256 private _buyTaxScale;
    uint256 private _sellTaxRate;
    uint256 private _sellTaxScale;
    ICurve private _curveAddress;


    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param name             curve token name
     * @param symbol           curve token symbol
     * @param reserveAsset     reserve asset address
     * @param buyTaxRate       value between 1 & 100 for owner revenue on mint/buy
     * @param sellTaxRate      value between 1 & 100 for owner revenue on burn/sell
     * @param reserveRatio     reserve ratio, represented in ppm (2-2000000)
     * @param curveAddress     address of the curve formula instance
     */
    constructor (
        string memory name,
        string memory symbol,
        address reserveAsset,
        uint256 buyTaxRate,
        uint256 buyTaxScale,
        uint256 sellTaxRate,
        uint256 sellTaxScale,
        uint32 reserveRatio,
        address curveAddress
    ) public ERC20(name, symbol) {
        require(reserveAsset != address(0), "BrincToken:constructor:Reserve asset invalid");
        require(buyTaxRate > 0, "BrincToken:constructor:Buy tax rate cant be 0%");
        require(buyTaxRate <= 100, "BrincToken:constructor:Buy tax rate cant be more than 100%");
        require(sellTaxRate > 0, "BrincToken:constructor:Sell tax rate cant be 0%");
        require(sellTaxRate <= 100, "BrincToken:constructor:Sell tax rate cant be more than 100%");
        require(buyTaxScale >= 100, "Buy tax scale can't be < 100");
        require(buyTaxScale <= 100000, "Buy tax scale can't be > 100 000");
        require(sellTaxScale >= 100, "Sell tax scale can't be < 100");
        require(sellTaxScale <= 100000, "Buy tax scale can't be > 100 000");
        _fixedReserveRatio = reserveRatio;
        _buyTaxRate = buyTaxRate;
        _buyTaxScale = buyTaxScale;
        _sellTaxRate = sellTaxRate;
        _sellTaxScale = sellTaxScale;
        _reserveAsset = IERC20(reserveAsset);
        _curveAddress = ICurve(curveAddress);
    }

    /**
     * @dev address of the underlining reserve asset
     *
     * @return reserveAssetAddress
     */
    /// #if_succeeds {:msg "Returns reserveAssetAddress"}
        /// $result == address(_reserveAsset);
    function reserveAsset() public view returns (address) {
        return address(_reserveAsset);
    }

    /**
     * @dev curve forumla instance address
     *
     * @return curveAddress
     */
    /// #if_succeeds  {:msg "Returns curveAddress"}
        /// $result == address(_curveAddress);
    function curveAddress() public view returns (address) {
        return address(_curveAddress);
    }

    /**
     * @dev reserve ratio set for the curve formula
     *
     * @return reserveRatio
     */
    /// #if_succeeds  {:msg "Returns reserveRatio"}
        /// $result == _fixedReserveRatio;
    function reserveRatio() public view returns (uint32) {
        return _fixedReserveRatio;
    }

    // Tax
    /**
     * @dev tax rate specified to direct reserve assets to owner on mint/buy
     *
     * @return buyTaxRate
     */
    /// #if_succeeds  {:msg "Returns taxRate"}
        /// $result == _buyTaxRate;
    function buyTaxRate() public view returns (uint256) {
        return _buyTaxRate;
    }

    /**
     * @dev Buy Tax Scale.
     * If buyTaxScale = 100 and buyTaxRate = 1, buyTax will effectively be 1%
     * If buyTaxScale = 1000 and buyTaxRate = 1, buyTax will effectively be 0.1%
     *
     * @return buyTaxScale
     */
    /// #if_succeeds {:msg "Returns buyTaxScale"}
        /// $result == _buyTaxScale;
    function buyTaxScale() public view returns (uint256) {
        return _buyTaxScale;
    }

    /**
     * @dev tax rate specified to direct reserve assets to owner on burn/sell
     *
     * @return sellTaxRate
     */
    /// #if_succeeds {:msg "Returns sellTaxRate"}
        /// $result == _sellTaxRate;
    function sellTaxRate() public view returns (uint256) {
        return _sellTaxRate;
    }

    /**
     * @dev Sell Tax Scale.
     * If sellTaxScale = 100 and sellTaxRate = 1, sellTax will effectively be 1%
     * If sellTaxScale = 1000 and sellTaxRate = 1, sellTax will effectively be 0.1%
     *
     * @return sellTaxScale
     */
    /// #if_succeeds {:msg "Returns sellTaxScale"}
        /// $result == _sellTaxScale;
    function sellTaxScale() public view returns (uint256) {
        return _sellTaxScale;
    }

    // Curve
    /**
     * @dev calculates the cost to mint a specified amount of collateral tokens
     *
     * @param amount tokens to mint
     *
     * @return cost
     */
    /// #if_succeeds {:msg "Returns correct mintCost"}
        /// $result == fundCost(totalSupply(), _reserveAsset.balanceOf(address(this)), _fixedReserveRatio, amount);
    function mintCost(uint256 amount) public view returns(uint256) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        return fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
    }

    /**
     * @dev calculates the reward for burning specified amount of curve tokens
     *
     * @param amount tokens to burn
     *
     * @return reward
     */
    /// #if_succeeds  {:msg "Returns burnReward"}
        /// $result == liquidateReserveAmount(totalSupply(), _reserveAsset.balanceOf(address(this)), _fixedReserveRatio, amount);
    function burnReward(uint256 amount) public view returns(uint256) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        return liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
    }

    /**
     * @dev initialises the curve, the total supply needs to be more than zero for
     * the curve to be calculated
     *
     * @param _firstReserve          initial reserve token
     * @param _firstSupply           initial supply of curve tokens
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The owner to hold initial minted token"}
        /// this.balanceOf(msg.sender) == _firstSupply;
    /// #if_succeeds {:msg "The contract should have the correct intial reserve amount"}
        /// _reserveAsset.balanceOf(address(this)) == _firstReserve;
    function init(uint256 _firstReserve, uint256 _firstSupply) external onlyOwner {
        require(totalSupply() == 0, "BrincToken:init:already minted");
        require(_reserveAsset.balanceOf(address(this)) == 0, "BrincToken:init:non-zero reserve asset balance");
        require(_reserveAsset.transferFrom(_msgSender(), address(this), _firstReserve), "BrincToken:init:Reserve asset transfer failed");
        _mint(_msgSender(), _firstSupply);
	}

    /**
     * @dev sets the tax rate stored in the buyTaxRate variable
     *
     * @param _rate                    new tax rate in percentage (integer between 1 and 100)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The buyTaxRate was set properly"}
        /// _buyTaxRate == _rate;
    function setBuyTaxRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100 && _rate >= 0, "BrincToken:setTax:invalid tax rate (1:100)");
        uint256 oldRate = _buyTaxRate;
        _buyTaxRate = _rate;
        emit BuyTaxRateChanged(oldRate, _buyTaxRate);
    }

    /**
     * @dev sets the buy tax scale stored in the buyTaxScale variable
     *
     * @param _scale new tax scale (integer between 100 and 100000)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The buyTaxScale was set properly"}
        /// _buyTaxScale == _scale;
    function setBuyTaxScale(uint256 _scale) external onlyOwner {
        require(_scale <= 100000 && _scale >= 100, "invalid buy tax scale (100:100000)");
        uint256 oldScale = _buyTaxScale;
        _buyTaxScale = _scale;
        emit BuyTaxScaleChanged(oldScale, _buyTaxScale);
    }

    /**
     * @dev sets the tax rate stored in the sellTaxRate variable
     *
     * @param _rate                    new tax rate in percentage (integer between 1 and 100)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The correct _sellTaxRate has been set"}
        /// _sellTaxRate == _rate;
    function setSellTaxRate(uint256 _rate) external onlyOwner {
        require(_rate <= 100 && _rate >= 0, "BrincToken:setTax:invalid tax rate (1:100)");
        uint256 oldRate = _sellTaxRate;
        _sellTaxRate = _rate;
        emit SellTaxRateChanged(oldRate, _sellTaxRate);
    }

    /**
     * @dev sets the sell tax scale stored in the sellTaxScale variable
     *
     * @param _scale new sell tax scale (integer between 100 and 100000)
     */
    /// #if_succeeds {:msg "The sender must be Owner"}
        /// old(msg.sender == this.owner());
    /// #if_succeeds {:msg "The sellTaxScale was set properly"}
        /// _sellTaxScale == _scale;
    function setSellTaxScale(uint256 _scale) external onlyOwner {
        require(_scale <= 100000 && _scale >= 100, "invalid sell tax scale (100:100000)");
        uint256 oldScale = _sellTaxScale;
        _sellTaxScale = _scale;
        emit SellTaxScaleChanged(oldScale, _sellTaxScale);
    }

    // CURVE
    /**
     * @dev given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * Formula:
     * return = _supply * ((1 + _amount / _reserveBalance) ^ (_reserveWeight / 1000000) - 1)
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of reserve tokens to get the target amount for
     *
     * @return target
     */
    /// #if_succeeds {:msg "The purchase amount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The purchase amount should be correct - case _reserveWeight = MAX_WEIGHT"}
        /// let postTax := _removeBuyTaxFromSpecificAmount(_amount) in
        /// _reserveWeight == 1000000 ==>  $result == _supply.mul(postTax) / _reserveBalance;

    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 postTax = _removeBuyTaxFromSpecificAmount(_amount);
        return _curveAddress.purchaseTargetAmount(
            _supply,
            _reserveBalance,
            _reserveWeight,
            postTax
        );
    }

     /**
     * @dev given a token supply, reserve balance, weight and a sell amount (in the main token),
     * calculates the target amount for a given conversion (in the reserve token)
     *
     * Formula:
     * return = _reserveBalance * (1 - (1 - _amount / _supply) ^ (1000000 / _reserveWeight))
     *
     * @param _supply          liquid token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveWeight   reserve weight, represented in ppm (1-1000000)
     * @param _amount          amount of liquid tokens to get the target amount for
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The sell amount should be correct - case _amount = 0"} 
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The sell amount should be correct - case _reserveWeight = MAX_WEIGHT"}
        /// _reserveWeight == 1000000 ==> $result == _removeSellTax(_reserveBalance.mul(_amount) / _supply);
    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 reserveValue = _curveAddress.saleTargetAmount(
            _supply,
            _reserveBalance,
            _reserveWeight,
            _amount
        );
        uint256 gross = _removeSellTax(reserveValue);
        return gross;
    }

     /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of requested pool tokens,
     * calculates the amount of reserve tokens required for purchasing the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (((_supply + _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio) - 1)
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          requested amount of pool tokens
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The fundCost amount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The fundCost amount should be correct - case _reserveRatio = MAX_WEIGHT"}
        /// _reserveRatio == 1000000 ==> $result == _addBuyTax(_curveAddress.fundCost(_supply, _reserveBalance, _reserveRatio, _amount));
    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 reserveTokenCost = _curveAddress.fundCost(
            _supply,
            _reserveBalance,
            _reserveRatio,
            _amount
        );
        uint256 net = _addBuyTax(reserveTokenCost);
        return net;
    }

    /**
     * @dev given a pool token supply, reserve balance, reserve ratio and an amount of pool tokens to liquidate,
     * calculates the amount of reserve tokens received for selling the given amount of pool tokens
     *
     * Formula:
     * return = _reserveBalance * (1 - ((_supply - _amount) / _supply) ^ (MAX_WEIGHT / _reserveRatio))
     *
     * @param _supply          pool token supply
     * @param _reserveBalance  reserve balance
     * @param _reserveRatio    reserve ratio, represented in ppm (2-2000000)
     * @param _amount          amount of pool tokens to liquidate
     *
     * @return reserve token amount
     */
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _amount = 0"}
        /// _amount == 0 ==> $result == 0;
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _amount = _supply"}
        /// _amount == _supply ==> $result == _removeSellTax(_reserveBalance);
    /// #if_succeeds {:msg "The liquidateReserveAmount should be correct - case _reserveRatio = MAX_WEIGHT"}
        /// _reserveRatio == 1000000 ==> $result == _removeSellTax(_amount.mul(_reserveBalance) / _supply);
    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 liquidateValue = _curveAddress.liquidateReserveAmount(
            _supply,
            _reserveBalance,
            _reserveRatio,
            _amount
        );
        uint256 gross = _removeSellTax(liquidateValue);
        return gross;
    }


    /**
     * @dev allows for the minting of tokens
     * @param account the account to mint the tokens to
     * @param amount the uint256 amount of tokens to mint
     *
     * @notice see note on mintForSpecificReserveAmount - this function should be used when there is
     * a target amount of main tokens (the tokens native to this contract) to be minted
     */
    /// #if_succeeds {:msg "The caller's BrincToken balance should be increase correct"}
        /// this.balanceOf(account) == old(this.balanceOf(account) + amount);
    /// #if_succeeds {:msg "The reserve balance should increase correct"} 
        /// _reserveAsset.balanceOf(address(this)) >= old(_reserveAsset.balanceOf(address(this)));
        // this will check if greater or equal to the old balance
        // will be equal in the case there is a 0 balance transfer
    /// #if_succeeds {:msg "The tax should go to the owner"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenCost := old(fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxDeducted := old(_removeBuyTax(reserveTokenCost)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + reserveTokenCost.sub(taxDeducted));
    function mint(address account, uint256 amount) public returns (bool) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenCost = fundCost(totalSupply(), reserveBalance, _fixedReserveRatio, amount);

        uint256 taxDeducted = _removeBuyTax(reserveTokenCost);
        require(
            _reserveAsset.transferFrom(
                _msgSender(),
                address(this),
                reserveTokenCost
            ),
            "BrincToken:mint:Reserve asset transfer for mint failed"
        );
        require(
            _reserveAsset.transfer(
                owner(),
                reserveTokenCost.sub(taxDeducted)
            ),
            "BrincToken:mint:Tax transfer failed"
        );
        _mint(account, amount);
        return true;
    }

    /**
     * @dev allows for the minting of tokens based on a target amount of reserve asset
     * @param account the account to mint the tokens to
     * @param amount the uint256 amount of reserve tokens to spend minting
     *
     * @notice the difference between this function and the default mint function is if the
     * amount of main token desired is specified (this is the case in the default mint function)
     * or if a specific amount of reserve token is being spent - this function would be used if the
     * the user has a specific amount of reserve asset (eg Dai) that they wish to spend
     */
    /// #if_succeeds {:msg "The caller's BrincToken balance should be increase correct"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let tokensToMint := old(purchaseTargetAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// msg.sender != owner() ==> this.balanceOf(account) == old(this.balanceOf(account) + tokensToMint);
    /// #if_succeeds {:msg "The reserve balance should increase by exact amount"}
        /// let taxDeducted := old(_removeBuyTaxFromSpecificAmount(amount)) in   
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) + amount - amount.sub(taxDeducted));
    /// #if_succeeds {:msg "The tax should go to the owner"}
        /// let taxDeducted := old(_removeBuyTaxFromSpecificAmount(amount)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner())) + amount.sub(taxDeducted);
    /// #if_succeeds {:msg "The result should be true"} $result == true;
    function mintForSpecificReserveAmount(address account, uint256 amount) public returns (bool) {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));

        uint256 taxDeducted = _removeBuyTaxFromSpecificAmount(amount);
        uint256 tokensToMint = purchaseTargetAmount(
            totalSupply(), 
            reserveBalance, 
            _fixedReserveRatio, 
            amount
        );

        require(
            _reserveAsset.transferFrom(
                _msgSender(),
                address(this),
                amount
            ),
            "BrincToken:mint:Reserve asset transfer for mint failed"
        );
        require(
            _reserveAsset.transfer(
                owner(),
                amount.sub(taxDeducted)
            ),
            "BrincToken:mint:Tax transfer failed"
        );
        _mint(account, tokensToMint);
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from the caller.
     * @param amount the uint256 amount of tokens to burn
     *
     * See {ERC20-_burn}.
     */

    /// #if_succeeds {:msg "The overridden burn should decrease caller's BrincToken balance"}
        /// this.balanceOf(_msgSender()) == old(this.balanceOf(_msgSender()) - amount);
    /// #if_succeeds {:msg "burn should add burn tax to the owner's balance"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burn should decrease BrincToken reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) - reserveTokenNet - taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burn should increase user's reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// msg.sender != owner() ==> _reserveAsset.balanceOf(_msgSender()) == old(_reserveAsset.balanceOf(_msgSender()) + reserveTokenNet);
    function burn(uint256 amount) public override {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenNet = liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
        _burn(_msgSender(), amount);

        uint256 taxAdded = _addSellTax(reserveTokenNet);
        require(_reserveAsset.transfer(owner(), taxAdded.sub(reserveTokenNet)), "BrincToken:burn:Tax transfer failed");
        require(_reserveAsset.transfer(_msgSender(), reserveTokenNet), "BrincToken:burn:Reserve asset transfer failed");
    }

    /**
     * @dev Allows an approved delgate to destroy tokens from another address
     * @param account the address to burn tokens from
     * @param amount the uint256 amount of tokens to approve
     */
    /// #if_succeeds {:msg "The overridden burnFrom should decrease caller's BrincToken balance"} 
        /// this.balanceOf(account) == old(this.balanceOf(account) - amount);
    /// #if_succeeds {:msg "burnFrom should add burn tax to the owner's balance"} 
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(owner()) == old(_reserveAsset.balanceOf(owner()) + taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burnFrom should decrease BrincToken reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// let taxAdded := old(_addSellTax(reserveTokenNet)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(address(this)) == old(_reserveAsset.balanceOf(address(this)) - reserveTokenNet - taxAdded.sub(reserveTokenNet));
    /// #if_succeeds {:msg "burnFrom should increase user's reserve balance by exact amount"}
        /// let reserveBalance := old(_reserveAsset.balanceOf(address(this))) in
        /// let reserveTokenNet := old(liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount)) in
        /// (msg.sender != owner() && address(this) != owner()) ==> _reserveAsset.balanceOf(_msgSender()) == old(_reserveAsset.balanceOf(_msgSender()) + reserveTokenNet);
    function burnFrom(address account, uint256 amount) public override {
        uint256 reserveBalance = _reserveAsset.balanceOf(address(this));
        uint256 reserveTokenNet = liquidateReserveAmount(totalSupply(), reserveBalance, _fixedReserveRatio, amount);
        super.burnFrom(account, amount);

        uint256 taxAdded = _addSellTax(reserveTokenNet);
        require(_reserveAsset.transfer(owner(), taxAdded.sub(reserveTokenNet)), "BrincToken:burnFrom:Tax transfer failed");
        require(_reserveAsset.transfer(account, reserveTokenNet), "BrincToken:burnFrom:Reserve asset transfer failed");
    }

    // ERC20Pausable
    /**
     * @dev Pauses the contract's transfer, mint & burn functions
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function pause() public onlyOwner() {
        _pause();
    }
    /**
     * @dev Unpauses the contract's transfer, mint & burn functions
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function unpause() public onlyOwner() {
        _unpause();
    }

    // ERC20Snapshot
    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     */
    /// #if_succeeds {:msg "The caller must be Owner"}
        /// old(msg.sender == this.owner());
    function snapshot() public onlyOwner() {
        _snapshot();
    }

    // Tax
    /**
     * @dev adds the buy tax to the cost of minting/buying tokens
     * @notice this function should be used when the user has not speicified a specific amount of
     * reserve tokens they are interested in spending, but rather a specific amount of collateralized
     * tokens they are interested in purchasing
     * @param reserveTokenAmount the initial amount that needs the taxed amount applied to it
     *
     * @return the post-tax cost to the user for minting
     */
    /// #if_succeeds {:msg "The correct tax is added to buy"}
        /// $result == reserveTokenAmount.mul(_buyTaxRate.add(_buyTaxScale)).div(_buyTaxScale);
    function _addBuyTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_buyTaxRate.add(_buyTaxScale)).div(_buyTaxScale);
    }

    /**
     * @dev reapplies the sell tax to the amount of reserves returned on burn/sell
     * @param reserveTokenAmount the initial amount that needs the taxed amount reapplied to it
     *
     * @return the pretax returns from selling
     */
    /// #if_succeeds {:msg "The correct tax is added to sell"}
        /// $result == reserveTokenAmount.mul(_sellTaxRate.add(_sellTaxScale)).div(_sellTaxScale);
    function _addSellTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_sellTaxRate.add(_sellTaxScale)).div(_sellTaxScale);
        // return (reserveTokenAmount.mul(_sellTaxScale)).div(_sellTaxScale.sub(_sellTaxRate));
    }

    /**
     * @dev removes the buy tax from the user-determined reserve token amount
     * @notice this function should be used when the user has speicified a specific amount of
     * reserve tokens they are interested in purchasing collateral tokens with, as opposed to 
     * a specific amount of collateralized
     * @param reserveTokenAmount the initial amount that needs the taxed amount removed from it
     *
     * @return the pretax cost of the collateral tokens
     */
    /// #if_succeeds {:msg "The correct tax removed from specific amount"}
        /// $result == reserveTokenAmount.mul(_buyTaxScale.sub(_buyTaxRate)).div(_buyTaxScale);
    function _removeBuyTaxFromSpecificAmount(uint256 reserveTokenAmount) internal view returns(uint256) {
        // uint256 upscaledTax = 1e18 - (_buyTaxRate.mul(1e16));
        // uint256 upscaledPreTax = reserveTokenAmount.mul(upscaledTax);
        // return upscaledPreTax / 1e18;
        return reserveTokenAmount.mul(_buyTaxScale.sub(_buyTaxRate)).div(_buyTaxScale);
    }

    /**
     * @dev removes the buy tax from the price of minting/buying (yielding the pretax amount)
     * @param reserveTokenAmount the initial amount that needs the tax rate removed from
     *
     * @return the pretax cost of the collateral tokens
     */
    /// #if_succeeds {:msg "The correct tax amount should be added"}
        /// $result == reserveTokenAmount.mul(_buyTaxScale).div(_buyTaxRate.add(_buyTaxScale));
    function _removeBuyTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_buyTaxScale).div(_buyTaxRate.add(_buyTaxScale));
    }

    /**
     * @dev removes the sell tax from the pretax returns of burning/selling
     * @param reserveTokenAmount the initial amount that needs the tax rate removed from
     *
     * @return the post-tax returns to the user from burning
     */
    /// #if_succeeds {:msg "The correct tax amount should be subtracted"}
        /// $result == reserveTokenAmount.mul(_sellTaxScale).div(_sellTaxRate.add(_sellTaxScale));
    function _removeSellTax(uint256 reserveTokenAmount) internal view returns(uint256) {
        return reserveTokenAmount.mul(_sellTaxScale).div(_sellTaxRate.add(_sellTaxScale));
        // return reserveTokenAmount.mul(_sellTaxScale.sub(_sellTaxRate)).div(_sellTaxScale);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC20,ERC20Snapshot,ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../math/SafeMath.sol";
import "../../utils/Arrays.sol";
import "../../utils/Counters.sol";
import "./ERC20.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */
abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }


    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        // mint
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        // burn
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        // transfer
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        // solhint-disable-next-line max-line-length
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
    Bonding Curve interface
*/
interface ICurve {
    function purchaseTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function saleTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function crossReserveTargetAmount(
        uint256 _sourceReserveBalance,
        uint32 _sourceReserveWeight,
        uint256 _targetReserveBalance,
        uint32 _targetReserveWeight,
        uint256 _amount
    ) external view returns (uint256);

    function fundCost(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function fundSupplyAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function liquidateReserveAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint32 _reserveRatio,
        uint256 _amount
    ) external view returns (uint256);

    function balancedWeights(
        uint256 _primaryReserveStakedBalance,
        uint256 _primaryReserveBalance,
        uint256 _secondaryReserveBalance,
        uint256 _reserveRateNumerator,
        uint256 _reserveRateDenominator
    ) external view returns (uint32, uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}