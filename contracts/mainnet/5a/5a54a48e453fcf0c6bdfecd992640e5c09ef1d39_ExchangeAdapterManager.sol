pragma solidity 0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20Extended is ERC20 {
    uint256 public decimals;
    string public name;
    string public symbol;

}

contract ComponentInterface {
    string public name;
    string public description;
    string public category;
    string public version;
}

contract ExchangeInterface is ComponentInterface {
    /*
     * @dev Checks if a trading pair is available
     * For ETH, use 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     * @param address _sourceAddress The token to sell for the destAddress.
     * @param address _destAddress The token to buy with the source token.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @return boolean whether or not the trading pair is supported by this exchange provider
     */
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId)
        external view returns(bool supported);

    /*
     * @dev Buy a single token with ETH.
     * @param ERC20Extended _token The token to buy, should be an ERC20Extended address.
     * @param uint _amount Amount of ETH used to buy this token. Make sure the value sent to this function is the same as the _amount.
     * @param uint _minimumRate The minimum amount of tokens to receive for 1 ETH.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here.
     * @return boolean whether or not the trade succeeded.
     */
    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external payable returns(bool success);

    /*
     * @dev Sell a single token for ETH. Make sure the token is approved beforehand.
     * @param ERC20Extended _token The token to sell, should be an ERC20Extended address.
     * @param uint _amount Amount of tokens to sell.
     * @param uint _minimumRate The minimum amount of ETH to receive for 1 ERC20Extended token.
     * @param address _depositAddress The address to send the bought tokens to.
     * @param bytes32 _exchangeId The exchangeId to choose. If it&#39;s an empty string, then the exchange will be chosen automatically.
     * @param address _partnerId If the exchange supports a partnerId, you can supply your partnerId here
     * @return boolean boolean whether or not the trade succeeded.
     */
    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId, address _partnerId
        ) external returns(bool success);
}

contract KyberNetworkInterface {

    function getExpectedRate(ERC20Extended src, ERC20Extended dest, uint srcQty)
        external view returns (uint expectedRate, uint slippageRate);

    function trade(
        ERC20Extended source,
        uint srcAmount,
        ERC20Extended dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId)
        external payable returns(uint);
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

contract OlympusExchangeAdapterInterface is Ownable {

    function supportsTradingPair(address _srcAddress, address _destAddress)
        external view returns(bool supported);

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount)
        external view returns(uint expectedRate, uint slippageRate);

    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external returns(bool success);

    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress
        ) external payable returns(bool success);

    function enable() external returns(bool);
    function disable() external returns(bool);
    function isEnabled() external view returns (bool success);

    function setExchangeDetails(bytes32 _id, bytes32 _name) external returns(bool success);
    function getExchangeDetails() external view returns(bytes32 _name, bool _enabled);

}

contract OlympusExchangeAdapterManagerInterface is Ownable {
    function pickExchange(ERC20Extended _token, uint _amount, uint _rate, bool _isBuying) public view returns (bytes32 exchangeId);
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId) external view returns(bool supported);
    function getExchangeAdapter(bytes32 _exchangeId) external view returns(address);
    function isValidAdapter(address _adapter) external view returns(bool);
    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate);
}

contract ExchangeAdapterManager is OlympusExchangeAdapterManagerInterface {

    mapping(bytes32 => OlympusExchangeAdapterInterface) public exchangeAdapters;
    bytes32[] public exchanges;
    uint private genExchangeId = 1000;
    mapping(address=>uint) private adapters;
    ERC20Extended private constant ETH_TOKEN_ADDRESS = ERC20Extended(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);


    event AddedExchange(bytes32 id);

    function addExchange(bytes32 _name, address _adapter)
    external onlyOwner returns(bool) {
        require(_adapter != 0x0);
        bytes32 id = keccak256(abi.encodePacked(_adapter, genExchangeId++));
        require(OlympusExchangeAdapterInterface(_adapter).setExchangeDetails(id, _name));
        exchanges.push(id);
        exchangeAdapters[id] = OlympusExchangeAdapterInterface(_adapter);
        adapters[_adapter]++;

        emit AddedExchange(id);
        return true;
    }

    function getExchanges() external view returns(bytes32[]) {
        return exchanges;
    }

    function getExchangeInfo(bytes32 _id)
    external view returns(bytes32 name, bool status) {
        OlympusExchangeAdapterInterface adapter = exchangeAdapters[_id];
        require(address(adapter) != 0x0);

        return adapter.getExchangeDetails();
    }

    function getExchangeAdapter(bytes32 _id)
    external view returns(address)
    {
        return address(exchangeAdapters[_id]);
    }

    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate) {

        if(_exchangeId != 0x0) {
            return exchangeAdapters[_exchangeId].getPrice(_sourceAddress, _destAddress, _amount);
        }
        bytes32 exchangeId = _sourceAddress == ETH_TOKEN_ADDRESS ?
        pickExchange(_destAddress, _amount, 0, true) :
        pickExchange(_sourceAddress, _amount, 0, false);
        if(exchangeId != 0x0) {
            OlympusExchangeAdapterInterface adapter = exchangeAdapters[exchangeId];
            return adapter.getPrice(_sourceAddress, _destAddress, _amount);
        }
        return(0, 0);
    }

    /// >0  : found exchangeId
    /// ==0 : not found
    function pickExchange(ERC20Extended _token, uint _amount, uint _rate, bool _isBuying) public view returns (bytes32 exchangeId) {

        int maxRate = -1;
        for (uint i = 0; i < exchanges.length; i++) {

            bytes32 id = exchanges[i];
            OlympusExchangeAdapterInterface adapter = exchangeAdapters[id];
            if (!adapter.isEnabled()) {
                continue;
            }
            uint adapterResultRate;
            uint adapterResultSlippage;
            if (_isBuying){
                (adapterResultRate,adapterResultSlippage) = adapter.getPrice(ETH_TOKEN_ADDRESS, _token, _amount);
            } else {
                (adapterResultRate,adapterResultSlippage) = adapter.getPrice(_token, ETH_TOKEN_ADDRESS, _amount);
            }
            int resultRate = int(adapterResultSlippage);


            if (adapterResultRate == 0) { // not support
                continue;
            }

            if (resultRate < int(_rate)) {
                continue;
            }

            if (resultRate >= maxRate) {
                maxRate = resultRate;
                return id;
            }
        }
        return 0x0;
    }

    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId) external view returns (bool) {
        OlympusExchangeAdapterInterface adapter;
        if(_exchangeId != ""){
            adapter = exchangeAdapters[id];
            if(!adapter.isEnabled()){
                return false;
            }
            if (adapter.supportsTradingPair(_srcAddress, _destAddress)) {
                return true;
            }
            return false;
        }
        for (uint i = 0; i < exchanges.length; i++) {
            bytes32 id = exchanges[i];
            adapter = exchangeAdapters[id];
            if (!adapter.isEnabled()) {
                continue;
            }
            if (adapter.supportsTradingPair(_srcAddress, _destAddress)) {
                return true;
            }
        }

        return false;
    }

    function isValidAdapter(address _adapter) external view returns (bool) {
        return adapters[_adapter] > 0;
    }
}