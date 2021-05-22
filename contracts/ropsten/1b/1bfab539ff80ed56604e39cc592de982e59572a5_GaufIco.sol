/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity 0.5.17;

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(ERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
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

contract ICO is Context, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // The  GAUF contract
    ERC20 private _gauf;

    // The link contract
    ERC20 private _link;

    // Address where funds are collected
    address payable private _wallet;

    // How many GAUF units a buyer gets per Link.
    // The rate is the conversion between Link and GAUF unit.
    uint256 private _linkRate;

    // How many GAUF units a buyer gets per Ether.
    // The rate is the conversion between Ether and GAUF unit.
    uint256 private _ethRate;

    // Amount of GAUF Delivered
    uint256 private _gaufDelivered;

    event GaufPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 linkRate, uint256 ethRate, address payable wallet, ERC20 link, ERC20 gauf) public {
        require(linkRate > 0, "ICO: linkRate shouldn't be Zero");
        require(ethRate > 0, "ICO: ethRate shouldn't be Zero");
        require(wallet != address(0), "ICO: wallet is the Zero address");
        require(address(gauf) != address(0), "ICO: token is the Zero address");

        _linkRate = linkRate;
        _ethRate = ethRate;
        _wallet = wallet;
        _link = link;
        _gauf = gauf;
    }

    function gaufAddress() public view returns (ERC20) {
        return _gauf;
    }

    function linkAddress() public view returns (ERC20) {
        return _link;
    }

    function teamWallet() public view returns (address payable) {
        return _wallet;
    }

    function linkRate() public view returns (uint256) {
        return _linkRate;
    }

    function ethRate() public view returns (uint256) {
        return _ethRate;
    }

    function gaufDelivered() public view returns (uint256) {
        return _gaufDelivered;
    }

    function buyGaufWithLink(uint256 linkAmount) public nonReentrant {
        address beneficiary = _msgSender();
        uint256 ContractBalance = _gauf.balanceOf(address(this));
        uint256 allowance = _link.allowance(beneficiary, address(this));

        require(linkAmount > 0, "You need to send at least one link");
        require(allowance >= linkAmount, "Check the Link allowance");

        // calculate GAUF amount
        uint256 _gaufAmount = _getLinkRate(linkAmount);

        _preValidatePurchase(beneficiary, _gaufAmount);

        require(_gaufAmount <= ContractBalance, "Not enough GAUF in the reserve");

        // update state
        _gaufDelivered = _gaufDelivered.add(_gaufAmount);

        _link.safeTransferFrom(beneficiary, address(this), linkAmount);

        _processPurchase(beneficiary, _gaufAmount);

        emit GaufPurchased(_msgSender(), beneficiary, linkAmount, _gaufAmount);

        _updatePurchasingState(beneficiary, _gaufAmount);

        _forwardLinkFunds(linkAmount);
        _postValidatePurchase(beneficiary, _gaufAmount);
    }

    function () external payable {
        buyGaufWithEther();
    }

    function buyGaufWithEther() public nonReentrant payable {
        address beneficiary = _msgSender();
        uint256 ethAmount = msg.value;
        uint256 ContractBalance = _gauf.balanceOf(address(this));

        require(ethAmount > 0, "You need to sendo at least some Ether");

        // calculate GAUF amount
        uint256 _gaufAmount = _getEthRate(ethAmount);

        _preValidatePurchase(beneficiary, _gaufAmount);

        require(_gaufAmount <= ContractBalance, "Not enough GauF in the reserve");

        // update state
        _gaufDelivered = _gaufDelivered.add(_gaufAmount);

        _processPurchase(beneficiary, _gaufAmount);

        emit GaufPurchased(_msgSender(), beneficiary, ethAmount, _gaufAmount);

        _updatePurchasingState(beneficiary, _gaufAmount);

        _forwardEtherFunds();

        _postValidatePurchase(beneficiary, _gaufAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 Amount) internal view {
        require(beneficiary != address(0), "ICO: beneficiary is the zero address");
        require(Amount != 0, "ICO: Amount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _postValidatePurchase(address beneficiary, uint256 Amount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _deliverGauf(address beneficiary, uint256 gaufAmount) internal {
        _gauf.safeTransfer(beneficiary, gaufAmount);
    }

    function _processPurchase(address beneficiary, uint256 gaufAmount) internal {
        _deliverGauf(beneficiary, gaufAmount);
    }
    
    function _updatePurchasingState(address beneficiary, uint256 Amount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _getLinkRate(uint256 linkAmount) internal view returns (uint256) {
        return linkAmount.mul(_linkRate);
    }

    function _getEthRate(uint256 ethAmount) internal view returns (uint256) {
        return ethAmount.mul(_ethRate);
    }

    function _forwardLinkFunds(uint256 linkAmount) internal {
        _link.safeTransfer(_wallet, linkAmount);
    }

    function _forwardEtherFunds() internal {
        _wallet.transfer(msg.value);
    }
}

contract LimitedUnitsIco is ICO {
    using SafeMath for uint256;

    uint256 private _maxGaufUnits;

    constructor (uint256 maxGaufUnits) public {
        require(maxGaufUnits > 0, "Max Capitalization shouldn't be Zero");
        _maxGaufUnits = maxGaufUnits;
    }

    function maxGaufUnits() public view returns (uint256) {
        return _maxGaufUnits;
    }

    function icoReached() public view returns (bool) {
        return gaufDelivered() >= _maxGaufUnits;
    }

    function _preValidatePurchase(address beneficiary, uint256 Amount) internal view {
        super._preValidatePurchase(beneficiary, Amount);
        require(gaufDelivered().add(Amount) <= _maxGaufUnits, "Max GAUF Units exceeded");
    }
}

contract GaufIco is LimitedUnitsIco {

    uint256 internal constant _hundredMillion = 10 ** 8;
    uint256 internal constant _oneGauf = 10**18;
    uint256 internal constant _maxGaufUnits = _hundredMillion * _oneGauf;
    uint256 internal constant _oneLinkToGauF = 400;
     uint256 internal constant _oneEthToGauF = 18000;
    
    address payable _wallet = 0x913C1B4D865fff3e3d12De237580F7825E38Aa09;
    ERC20 internal _link = ERC20(0xF0A9A7a0a6CEd9ef7DD4631C86C3D21279cE7C3E);
    ERC20 internal _gauf = ERC20(0x42EF77B975e7260d28c408236B7581666dcD226C);

    constructor () public
        ICO(_oneLinkToGauF, _oneEthToGauF, _wallet, _link, _gauf) 
        LimitedUnitsIco(_maxGaufUnits)
    {

    }
}