pragma solidity ^0.4.25;

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title EtherFeeSplitter
 */
contract EtherFeeSplitter {
    using AddressUtils for address;
    using SafeMath for uint256;

    // Address where client funds are collected
    address public wallet;

    // Address where service provider fees are collected
    address public providerWallet;

    // Two fee thresholds separating the raised volume into three partitions
    uint256 public feeThreshold1;
    uint256 public feeThreshold2;

    // Three percentage levels for fee calculation in each partition
    uint256 public lowFeePercentage;
    uint256 public mediumFeePercentage;
    uint256 public highFeePercentage;

    uint256 public totalReleased;
    uint256 public releasedFees;
    uint256 public releasedFunds;

    bool public instantFeeEnabled;

    address public owner;

    event LogEtherFeeSplitterCreated(
        address caller,
        address wallet,
        address indexed providerWallet,
        uint256 indexed feeThreshold1,
        uint256 indexed feeThreshold2,
        uint256 lowFeePercentage,
        uint256 mediumFeePercentage,
        uint256 highFeePercentage
    );
    event LogAmountReceived(
        address indexed caller,
        uint256 amount
    );
    event LogFundsWithdrawn(
        address indexed caller,
        uint256 fundsPayment,
        uint256 totalReceived,
        uint256 totalReleased
    );
    event LogFeesWithdrawn(
        address indexed caller,
        uint256 feePayment,
        uint256 totalReceived,
        uint256 totalReleased
    );

    constructor(
        address _wallet,
        address _providerWallet,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        bool _enableInstantFee
    )
    public
    {
        require(_wallet != address(0), "_wallet is zero"); // Is this covered below?
        require(!_wallet.isContract(), "_wallet is contract");
        require(providerWallet == 0 || !_providerWallet.isContract(), "_providerWallet is contract");
        require(_feeThreshold2 >= _feeThreshold1, "_feeThreshold2 is lower than _feeThreshold1");
        require(0 <= _lowFeePercentage && _lowFeePercentage <= 100, "_lowFeePercentage not in range [0, 100]");
        require(0 <= _mediumFeePercentage && _mediumFeePercentage <= 100, "_mediumFeePercentage not in range [0, 100]");
        require(0 <= _highFeePercentage && _highFeePercentage <= 100, "_highFeePercentage not in range [0, 100]");

        wallet = _wallet;
        providerWallet = _providerWallet;
        feeThreshold1 = _feeThreshold1;
        feeThreshold2 = _feeThreshold2;
        lowFeePercentage = _lowFeePercentage;
        mediumFeePercentage = _mediumFeePercentage;
        highFeePercentage = _highFeePercentage;
        instantFeeEnabled = _enableInstantFee;
        owner = msg.sender;

        emit LogEtherFeeSplitterCreated(
            msg.sender,
            _wallet,
            _providerWallet,
            _feeThreshold1,
            _feeThreshold2,
            _lowFeePercentage,
            _mediumFeePercentage,
            _highFeePercentage
        );
    }

    function feePaymentEnabled() public view returns(bool feeEnabled) {
        return providerWallet != 0;
    }

    function currentFeePercentage() public view returns (uint256 percentage) {
        uint256 totalReceived = address(this).balance.add(totalReleased);
        return feePercentage(totalReceived);
    }

    function withdrawFunds() public {
        require(msg.sender == wallet, "invalid withdraw msg.sender");

        uint256 totalReceived = address(this).balance.add(totalReleased);
        uint256 feePerc = feePercentage(totalReceived);
        uint256 fundsPerc = feePaymentEnabled() ? uint256(100).sub(feePerc) : 100;

        uint256 fundsPayment = totalReceived.mul(fundsPerc).div(100).sub(releasedFunds);
        require(fundsPayment != 0, "no more funds to withdraw");
        require(address(this).balance >= fundsPayment, "insufficient balance for funds");

        releasedFunds = releasedFunds.add(fundsPayment);
        totalReleased = totalReleased.add(fundsPayment);

        // solium-disable-next-line arg-overflow
        emit LogFundsWithdrawn(msg.sender, fundsPayment, totalReceived, totalReleased);

        msg.sender.transfer(fundsPayment);
    }

    function withdrawFees() public {
        require(feePaymentEnabled() && msg.sender == providerWallet, "invalid withdrawFees msg.sender");

        uint256 totalReceived = address(this).balance.add(totalReleased);
        uint256 feePerc = feePercentage(totalReceived);

        uint256 feePayment = totalReceived.mul(feePerc).div(100).sub(releasedFees);
        require(feePayment != 0, "no more fees to withdraw");
        require(address(this).balance >= feePayment, "insufficient balance for fees");

        releasedFees = releasedFees.add(feePayment);
        totalReleased = totalReleased.add(feePayment);

        // solium-disable-next-line arg-overflow
        emit LogFeesWithdrawn(msg.sender, feePayment, totalReceived, totalReleased);

        msg.sender.transfer(feePayment);
    }

    function feePercentage(uint256 totalReceived) internal view returns (uint256 percentage) {
        return totalReceived < feeThreshold1 ? lowFeePercentage :
            totalReceived < feeThreshold2 ? mediumFeePercentage :
            highFeePercentage;
    }

    function setInstantFee(bool _instantFeeEnabled) public {
        require(msg.sender == owner, "only owner");
        instantFeeEnabled = _instantFeeEnabled;
    }

    function () public payable {
        emit LogAmountReceived(msg.sender, msg.value);
        if(instantFeeEnabled) {
            require(msg.value != 0, "");

            uint256 feePerc = feePercentage(msg.value);
            uint256 feePaymentProvider = msg.value.mul(feePerc).div(100);
            
            uint256 amountToWallet = msg.value.sub(feePaymentProvider);

            address(providerWallet).transfer(feePaymentProvider);
            address(wallet).transfer(amountToWallet);

            releasedFees = releasedFees.add(feePaymentProvider);
            releasedFunds = releasedFunds.add(amountToWallet);

            totalReleased = totalReleased.add(msg.value);
        }
    }
}