pragma solidity ^0.5.13;

import "./ERC20.sol";
import "./DateTime.sol";
import "./Ownable.sol";

contract StableCoin is ERC20, DateTime, Ownable {
    using SafeMath for uint256;

    address public tokenIssuer;
    uint256 public lastOxydationDate;

    event Oxydated(address holder, uint256 amount);
    event TimestampComparaison(uint256 newTimestamp, uint256 oldTimestamp);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _decimals,
        address _tokenIssuer
    ) public ERC20(_tokenName, _tokenSymbol, _decimals) Ownable() {
        lastOxydationDate = now;
        tokenIssuer = _tokenIssuer;
    }

    // change address that get fees from oxydation
    function setTokenIssuer(address _addressPallaOneFees) public onlyOwner {
        tokenIssuer = _addressPallaOneFees;
    }

    function mint(address _to, uint256 _tokenAmount) public onlyOwner {
        _mint(_to, _tokenAmount);
    }

    //Mint tokens to each each beneficiary
    function mints(address[] calldata _recipients, uint256[] calldata _values) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            mint(_recipients[i], _values[i]);
        }
    }

    function burn(address _account, uint256 _value) public onlyOwner {
        _burn(_account, _value);
    }

    //Burn tokens to each each beneficiary
    function burns(address[] calldata _recipients, uint256[] calldata _values) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            burn(_recipients[i], _values[i]);
        }
    }
    // can accept ether
    function() external payable {}

    // give number of ether owned by smart contract
    function getBalanceEthSmartContract() public view returns (uint256) {
        return address(this).balance;
    }

    // transfer smart contract balance to owner
    function withdrawEther(uint256 amount) public onlyOwner {
        address payable ownerPayable = address(uint160(Ownable.owner()));
        ownerPayable.transfer(amount);
    }

    // monthly oxydation for all investors
    function oxydation(address[] calldata holders) external {
        for (uint256 i = 0; i < holders.length; i++) {
            emit TimestampComparaison(getMonth(lastOxydationDate), getMonth(now));
            if (getMonth(lastOxydationDate) != getMonth(now)) {
                // once a month
                uint256 balanceCurrent = balanceOf(holders[i]);
                uint256 toOxyde = balanceCurrent.div(1200); // 1% annual over 12 months
                _burn(holders[i], toOxyde);
                _mint(tokenIssuer, toOxyde);
                emit Oxydated(holders[i], toOxyde);
            }
        }
        lastOxydationDate = now;
    }

    function Now() external view returns (uint256){
      return (now);
  }

}