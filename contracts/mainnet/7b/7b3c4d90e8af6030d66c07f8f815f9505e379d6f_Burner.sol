pragma solidity ^0.4.18;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 * @dev From https://github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.8.0/contracts/lifecycle/Destructible.sol
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}


/// @dev From https://github.com/KyberNetwork/smart-contracts/blob/master/contracts/ERC20Interface.sol
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/// @title Contract for a burnable ERC
contract BurnableErc20 is ERC20 {
    function burn(uint value) external;
}

contract KyberNetwork {
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
}


/// @title A contract to burn ERC20 tokens from ETH
/// @notice Sends the ETH on the contract to kyber for conversion to ERC20
///  The converted ERC20 is then burned
/// @author Request Network
contract Burner is Destructible {
    /// Kyber contract that will be used for the conversion
    KyberNetwork public kyberContract;

    // Contract for the ERC20
    BurnableErc20 public destErc20;

    /// @param _destErc20 Destination token
    /// @param _kyberContract Kyber contract to use
    function Burner(address _destErc20, address _kyberContract) public {
        // Check inputs
        require(_destErc20 != address(0));
        require(_kyberContract != address(0));

        destErc20 = BurnableErc20(_destErc20);
        kyberContract = KyberNetwork(_kyberContract);
    }
    
    /// Fallback function to receive the ETH to burn later
    function() public payable { }

    /// @dev Main function. Trade the ETH for ERC20 and burn them
    /// @param _maxSrcAmount Maximum amount of ETH to convert. If set to 0, all ETH on the
    ///  contract will be burned
    /// @param _maxDestAmount A limit on the amount of converted ERC20 tokens. Default value is MAX_UINT
    /// @param _minConversionRate The minimal conversion rate. Default value is 1 (market rate)
    /// @return amount of dest ERC20 tokens burned
    function burn(uint _maxSrcAmount, uint _maxDestAmount, uint _minConversionRate)
        external
        returns(uint)
    {
        // ETH to convert on Kyber, by default the amount of ETH on the contract
        // If _maxSrcAmount is defined, ethToConvert = min(balance on contract, _maxSrcAmount)
        uint ethToConvert = address(this).balance;
        if (_maxSrcAmount != 0 && _maxSrcAmount < ethToConvert) {
            ethToConvert = _maxSrcAmount;
        }

        // Set maxDestAmount to MAX_UINT if not sent as parameter
        uint maxDestAmount = _maxDestAmount != 0 ? _maxDestAmount : 2**256 - 1;

        // Set minConversionRate to 1 if not sent as parameter
        // A value of 1 will execute the trade according to market price in the time of the transaction confirmation
        uint minConversionRate = _minConversionRate != 0 ? _minConversionRate : 1;

        // Convert the ETH to ERC20
        // erc20ToBurn is the amount of the ERC20 tokens converted by Kyber that will be burned
        uint erc20ToBurn = kyberContract.trade.value(ethToConvert)(
            // Source. From Kyber docs, this value denotes ETH
            ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
            
            // Source amount
            ethToConvert,

            // Destination. Downcast BurnableErc20 to ERC20
            ERC20(destErc20),
            
            // destAddress: this contract
            this,
            
            // maxDestAmount
            maxDestAmount,
            
            // minConversionRate 
            minConversionRate,
            
            // walletId
            0
        );

        // Burn the converted ERC20 tokens
        destErc20.burn(erc20ToBurn);

        return erc20ToBurn;
    }

    /**
    * @notice Sets the KyberNetwork contract address.
    */  
    function setKyberNetworkContract(address _kyberNetworkAddress) 
        external
        onlyOwner
    {
        kyberContract = KyberNetwork(_kyberNetworkAddress);
    }
}