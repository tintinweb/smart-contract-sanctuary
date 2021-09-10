// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**************************************************************************************************
 **************************************************************************************************
 **************************************************************************************************
 ***********   ********  *****         ***             ****          ***            ****  ***********
 ***********  *  ******  *****  ****************  *********  ***********  ***************************
 ***********  **  *****  *****  ****************  *********  ***********  **************  ***********
 ***********  ***  ****  *****         *********  *********          ***          ******  ***********
 ***********  ****  ***  *****  ****************  *********  ***********  **************  ***********
 ***********  *****  **  *****  ****************  *********  ***********  **************  ***********
 ***********  ******  *  *****  ****************  *********  ***********  **************  ***********
 ***********  ********   *****         *********  *********          ***  **************  ***********
 **************************************************************************************************
 **************************************************************************************************
 **************************************************************************************************
 **************************************************************************************************
 ************************************************************************************************** */

import "./Ownable.sol";
import "./ERC20Votes.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";

contract NEFI is ERC20Votes, ERC20Burnable, Pausable, Ownable {
    bool isPartnerUnlocked = false;
    bool isOwnerUnlocked = false;

    uint256 constant INIT_TOKENS = 26500000 * 1e18;

    uint256 LOCKED_AMOUNT = 28500000 * 1e18;

    uint256 minLockedDeadline;

    address public partnerAddress;
    address public govAddress;
    address public lockerAddress;

    constructor()
        ERC20("Netefi Network Token", "NEFI")
        ERC20Permit("netefinetwork")
    {
        super._mint(_msgSender(), INIT_TOKENS);
        minLockedDeadline = block.timestamp + 30 days;
    }

    modifier onlyUnlocked() {
        require(
            isPartnerUnlocked && isOwnerUnlocked,
            "Permission: token has locked"
        );
        _;
    }

    modifier onlyGov() {
        require(_msgSender() == govAddress, "Permission: only governor");
        _;
    }

    modifier onlyPartner() {
        require(_msgSender() == partnerAddress, "Permission: only partner");
        _;
    }

    modifier onlyNetefiLocker() {
        require(
            _msgSender() == lockerAddress,
            "Permission: only netefi locker"
        );
        _;
    }

    modifier whenPassMinLock() {
        require(
            block.timestamp > minLockedDeadline,
            "Permision: in min locked duration"
        );
        _;
    }

    /** Mint */
    function mint(address to, uint256 amount)
        public
        whenNotPaused
        onlyUnlocked
        onlyGov
    {
        require(to != address(0), "NEFI: to address invalid");
        require(amount > 0, "NEFI: amount invalid");
        require(
            (totalSupply() + amount) <= (_maxSupply() - LOCKED_AMOUNT),
            "NEFI: exceeded mint quota"
        );
        super._mint(to, amount);
    }

    function mintFromLocker(address to, uint256 amount)
        public
        whenNotPaused
        whenPassMinLock
        onlyNetefiLocker
    {
        require(to != address(0), "NEFI: to address invalid");
        require(amount > 0 && amount <= LOCKED_AMOUNT, "NEFI: amount invalid");
        super._mint(to, amount);
        LOCKED_AMOUNT = LOCKED_AMOUNT - amount;
    }

    /** partner && gov && locker */
    function setupPartnerAddress(address _partnerAddress) public onlyOwner {
        require(
            partnerAddress == address(0) && _partnerAddress != address(0),
            "NEFI: partner has set"
        );
        partnerAddress = _partnerAddress;
    }

    function setupLockerAddress(address _lockerAddress) public onlyOwner {
        require(
            lockerAddress == address(0) && _lockerAddress != address(0),
            "NEFI: locker has set"
        );
        lockerAddress = _lockerAddress;
    }

    function setupGovAddress(address _govAddress) public onlyOwner {
        require(
            govAddress == address(0) && _govAddress != address(0),
            "NEFI: governor has set"
        );
        govAddress = _govAddress;
    }

    function unlockFromPartner() public onlyPartner {
        require(isPartnerUnlocked == false, "NEFI: partner done unlocked");
        isPartnerUnlocked = true;
    }

    function unlockFromOwner() public onlyOwner {
        require(isOwnerUnlocked == false, "NEFI: owner done unlocked");
        isOwnerUnlocked = true;
    }

    function burn(uint256 amount) public override(ERC20Burnable) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override(ERC20Burnable)
    {
        super.burnFrom(account, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    // circuit breaker
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}