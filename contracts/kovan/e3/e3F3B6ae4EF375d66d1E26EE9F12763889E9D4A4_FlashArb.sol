pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";
import { Ownable } from "./Ownable.sol";

interface OrFeedInterface {
  function getExchangeRate ( string calldata fromSymbol, string calldata  toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata  symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata  symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
  function arb(address  fundsReturnToAddress,  address liquidityProviderContractAddress, string[] calldata   tokens,  uint256 amount, string[] calldata  exchanges) external payable returns (bool);
}

// This contract will be flash loan only
contract FlashArb is FlashLoanReceiverBase {

    ILendingPoolAddressesProvider provider;
    using SafeMath for uint256;
    address lendingPoolAddr;
    address constant ETHER = address(0);
    address private _owner;

       constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider)  public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
       }

    function executeOperation(address[] calldata _reserve,
                              uint256[] calldata _amount,
                              uint256[] calldata _premiums, 
                              address initiator, 
                              bytes calldata _params) 
                              override external returns (bool){
        
        // kovan orfeed 0x31a29958301C407D4b4bf0D53DAC1F2d154d9d8d
        // mainnet orfeed 0x8316B082621CFedAB95bf4a44a1d4B64a6ffc336
        OrFeedInterface orfeed = OrFeedInterface(0x31a29958301C407D4b4bf0D53DAC1F2d154d9d8d);
        (string[] memory tokenOrder, string[] memory exchangeOrder) =  abi.decode(_params,(string[], string[]));
        IERC20(_reserve[0]).approve(0x31a29958301C407D4b4bf0D53DAC1F2d154d9d8d, 10000000000000000000000000000);
        orfeed.arb(address(this), address(this), tokenOrder, _amount[0], exchangeOrder);
        uint amountOwing = _amount[0] + _premiums[0];
        IERC20(_reserve[0]).approve(address(_lendingPool), amountOwing);
        
        return true;
    }

    function myflashloan(address _asset, string[] calldata tokenOrder, string[] calldata exchangeOrder, uint256 _amount) external onlyOwner {
        bytes memory data = abi.encode(tokenOrder, exchangeOrder);
        address[] memory asset = new address[](1);
        asset[0] = _asset;
        uint256[] memory amount = new uint256[](1);
        amount[0] = _amount * 1000000000000000000; // convert to gwei
        uint256[] memory mode = new uint256[](1);
        mode[0] = 0;
        uint16 referralCode = 0;
        ILendingPool lendingPool = ILendingPool(_addressesProvider.getLendingPool());

        lendingPool.flashLoan(address(this), asset, amount, mode, address(this), data, referralCode);
    }


    function flashRepay(ILendingPool _lendingPool, address _repayAsset, uint256 _repayAmt) public {
        
        // approve the repayment from this contract
        IERC20(_repayAsset).approve(lendingPoolAddr, _repayAmt);
        
        _lendingPool.repay(
            _repayAsset, 
            _repayAmt, 
            1, 
            address(this)
        );
    }

    /**
     * @dev Withdraw asset.
     * @param _assetAddress Asset to be withdrawn.
     */
    function withdraw(address _assetAddress) public onlyOwner {
        uint assetBalance;
        if (_assetAddress == ETHER) {
            address self = address(this); // workaround for a possible solidity bug
            assetBalance = self.balance;
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_assetAddress).balanceOf(address(this));
            IERC20(_assetAddress).safeTransfer(msg.sender, assetBalance);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}