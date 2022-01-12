// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";


contract TxDAO is ERC20, Ownable{
    uint256 public constant MAX_SUPPLY = uint248(100_000_000_000 * 1000_000_000);
    mapping(address => mapping(uint16 => bool)) public claimed;
    mapping(address => uint256) public promoteAmount;
    mapping(address => uint16) public promoteNumber;
    event ClaimSet(address _from, uint16 _chainID, uint256 _amount);
    uint8 public promotePercent = 1;
    address private cSigner = 0x95e9d9Ddf6f70AEB909a538A18eA2CED2B732452;
    constructor() ERC20("sss", "sss") {

    }
    function setCsigner(address _address) public onlyOwner {
        cSigner = _address;
    }
    function setPromotePercent(uint8 _percent) public onlyOwner {
        promotePercent = _percent;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function claim(address _address, uint16 _chainID, uint256 amountV, bytes32 r, bytes32 s) external {
        require(msg.sender != _address, "promote account should not be yourself");
        uint256 _amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        require(_amount > 0, "Airdrop amount must be greater than 0");
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _chainID, _amount));
        require(ecrecover(messageHash, v, r, s) == cSigner, "Invalid signer");
        uint256 promote_amount = 0;
        if (_address != 0x0000000000000000000000000000000000000000 && msg.sender != owner()) {
            promote_amount = _amount * promotePercent / 100;
            _mint(_address, promote_amount);
            promoteAmount[_address] += promote_amount;
            promoteNumber[_address] += 1;
        }
        address receiver = msg.sender;
        if (msg.sender == owner()) {
            receiver = _address;
        }
        claimed[receiver][_chainID] = true;
        _mint(receiver, _amount);

        emit ClaimSet(receiver, _chainID, _amount);

    }


}