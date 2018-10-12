pragma solidity ^0.4.24;


contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract EthTweetMe is Ownable {
    using SafeMath for uint256;

    // Supported token symbols mapped to ERC20 contract addr
    mapping(string => address) tokens;

    address webappAddress;
    address feePayoutAddress;
    uint256 public feePercentage = 5;
    uint256 public minAmount = 0.000001 ether;
    uint256 public webappMinBalance = 0.000001 ether;

    struct Influencer {
        address influencerAddress;
        uint256 charityPercentage;
        address charityAddress;
    }
    // Map influencer&#39;s twitterHandle to Influencer struct
    mapping(string => Influencer) influencers;


    event InfluencerAdded(string _influencerTwitterHandle);
    event FeePercentageUpdated(uint256 _feePercentage);
    event Deposit(address _address, uint256 _amount);


    modifier onlyWebappOrOwner() {
        require(msg.sender == webappAddress || msg.sender == owner);
        _;
    }


    constructor() public {
        webappAddress = msg.sender;
        feePayoutAddress = msg.sender;
    }

    // Fallback function. Allow users to pay the contract directly
    function() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function updateFeePercentage(uint256 _feePercentage) external onlyWebappOrOwner {
        require(_feePercentage <= 100);
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(feePercentage);
    }

    function updateMinAmount(uint256 _minAmount) external onlyWebappOrOwner {
        minAmount = _minAmount;
    }
    function updateWebappMinBalance(uint256 _minBalance) external onlyWebappOrOwner {
        webappMinBalance = _minBalance;
    }

    function updateWebappAddress(address _address) external onlyOwner {
        webappAddress = _address;
    }

    function updateFeePayoutAddress(address _address) external onlyOwner {
        feePayoutAddress = _address;
    }

    function updateInfluencer(
            string _twitterHandle,
            address _influencerAddress,
            uint256 _charityPercentage,
            address _charityAddress) external onlyWebappOrOwner {
        require(_charityPercentage <= 100);
        require((_charityPercentage == 0 && _charityAddress == 0x0) || (_charityPercentage > 0 && _charityAddress != 0x0));
        if (influencers[_twitterHandle].influencerAddress == 0x0) {
            // This is a new Influencer!
            emit InfluencerAdded(_twitterHandle);
        }
        influencers[_twitterHandle] = Influencer(_influencerAddress, _charityPercentage, _charityAddress);
    }

    function sendEthTweet(uint256 _amount, bool _isERC20, string _symbol, bool _payFromMsg, string _influencerTwitterHandle, uint256 _additionalFee) private {
        require(
            (!_isERC20 && _payFromMsg && msg.value == _amount) ||
            (!_isERC20 && !_payFromMsg && _amount <= address(this).balance) ||
            _isERC20
        );
        require(_additionalFee == 0 || _amount > _additionalFee);

        ERC20Basic erc20;
        if (_isERC20) {
            // Now do ERC20-specific checks
            // Must be an ERC20 that we support
            require(tokens[_symbol] != 0x0);

            // The ERC20 funds should have already been transferred
            erc20 = ERC20Basic(tokens[_symbol]);
            require(erc20.balanceOf(address(this)) >= _amount);
        }

        // influencer must be a known twitterHandle
        Influencer memory influencer = influencers[_influencerTwitterHandle];
        require(influencer.influencerAddress != 0x0);

        uint256[] memory payouts = new uint256[](4);    // 0: influencer, 1: charity, 2: fee, 3: webapp
        uint256 hundred = 100;
        if (_additionalFee > 0) {
            payouts[3] = _additionalFee;
            _amount = _amount.sub(_additionalFee);
        }
        if (influencer.charityPercentage == 0) {
            payouts[0] = _amount.mul(hundred.sub(feePercentage)).div(hundred);
            payouts[2] = _amount.sub(payouts[0]);
        } else {
            payouts[1] = _amount.mul(influencer.charityPercentage).div(hundred);
            payouts[0] = _amount.sub(payouts[1]).mul(hundred.sub(feePercentage)).div(hundred);
            payouts[2] = _amount.sub(payouts[1]).sub(payouts[0]);
        }

        require(payouts[0].add(payouts[1]).add(payouts[2]) == _amount);

        if (payouts[0] > 0) {
            if (!_isERC20) {
                influencer.influencerAddress.transfer(payouts[0]);
            } else {
                erc20.transfer(influencer.influencerAddress, payouts[0]);
            }
        }
        if (payouts[1] > 0) {
            if (!_isERC20) {
                influencer.charityAddress.transfer(payouts[1]);
            } else {
                erc20.transfer(influencer.charityAddress, payouts[1]);
            }
        }
        if (payouts[2] > 0) {
            if (!_isERC20) {
                if (webappAddress.balance < webappMinBalance) {
                    // Redirect the fee funds into webapp
                    payouts[3] = payouts[3].add(payouts[2]);
                } else {
                    feePayoutAddress.transfer(payouts[2]);
                }
            } else {
                erc20.transfer(feePayoutAddress, payouts[2]);
            }
        }
        if (payouts[3] > 0) {
            if (!_isERC20) {
                webappAddress.transfer(payouts[3]);
            } else {
                erc20.transfer(webappAddress, payouts[3]);
            }
        }
    }

    // Called by users directly interacting with the contract, paying in ETH
    //  Users are paying their own gas so no additional fee.
    function sendEthTweet(string _influencerTwitterHandle) external payable {
        sendEthTweet(msg.value, false, "ETH", true, _influencerTwitterHandle, 0);
    }

    // Called by the webapp on behalf of Other/QR code payers.
    //  Charge an additional fee since we&#39;re paying for gas.
    function sendPrepaidEthTweet(uint256 _amount, string _influencerTwitterHandle, uint256 _additionalFee) external onlyWebappOrOwner {
        /* require(_amount <= address(this).balance); */
        sendEthTweet(_amount, false, "ETH", false, _influencerTwitterHandle, _additionalFee);
    }

    /****************************************************************
    *   ERC-20 support
    ****************************************************************/
    function addNewToken(string _symbol, address _address) external onlyWebappOrOwner {
        tokens[_symbol] = _address;
    }
    function removeToken(string _symbol) external onlyWebappOrOwner {
        require(tokens[_symbol] != 0x0);
        delete(tokens[_symbol]);
    }
    function supportsToken(string _symbol, address _address) external constant returns (bool) {
        return (tokens[_symbol] == _address);
    }
    function contractTokenBalance(string _symbol) external constant returns (uint256) {
        require(tokens[_symbol] != 0x0);
        ERC20Basic erc20 = ERC20Basic(tokens[_symbol]);
        return erc20.balanceOf(address(this));
    }

    // Called as the second step by users directly interacting with the contract.
    //  Users are paying their own gas so no additional fee.
    function sendERC20Tweet(uint256 _amount, string _symbol, string _influencerTwitterHandle) external {
        // Pull in the pre-approved ERC-20 funds
        ERC20Basic erc20 = ERC20Basic(tokens[_symbol]);
        require(erc20.transferFrom(msg.sender, address(this), _amount));

        sendEthTweet(_amount, true, _symbol, false, _influencerTwitterHandle, 0);
    }

    // Called by the webapp on behalf of Other/QR code payers.
    //  Charge an additional fee since we&#39;re paying for gas.
    function sendPrepaidERC20Tweet(uint256 _amount, string _symbol, string _influencerTwitterHandle, uint256 _additionalFee) external onlyWebappOrOwner {
        sendEthTweet(_amount, true, _symbol, false, _influencerTwitterHandle, _additionalFee);
    }


    // Public accessors
    function getInfluencer(string _twitterHandle) external constant returns(address, uint256, address) {
        Influencer memory influencer = influencers[_twitterHandle];
        return (influencer.influencerAddress, influencer.charityPercentage, influencer.charityAddress);
    }

}