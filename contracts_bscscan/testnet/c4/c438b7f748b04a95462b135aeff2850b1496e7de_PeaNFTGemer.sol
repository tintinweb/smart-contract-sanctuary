// SPDX-License-Identifier: UNLICENSED
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IPeaRouter.sol";
import "./IPeaNFT.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

contract PeaNFTGemer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPeaRouter public peaRouter;
    IPeaNFT public peaToken;
    IERC20 public peanToken;

    bytes32 private privateKey;
    bytes32 private seedKey;

    mapping(address => uint256) lastBlockNumberCalled;

    constructor(
        address _peaRouter,
        address _peanToken,
        address _peaToken
    ) {
        peaRouter = IPeaRouter(_peaRouter);
        peanToken = IERC20(_peanToken);
        peaToken = IPeaNFT(_peaToken);
        _generateKey(bytes32(block.timestamp));
        seedKey = bytes32("PeaNFTGemer");
    }

    function SAFU(address _admin) public onlyOwner {
        payable(_admin).transfer(address(this).balance);
    }

    function generateKey(string memory _key) external onlyOwner {
        seedKey = keccak256(abi.encodePacked(_key));
    }

    function _generateKey(bytes32 _key) internal {
        privateKey = _key;
    }

    modifier oncePerBlock(address user) {
        require(
            lastBlockNumberCalled[user] < block.number,
            "Only callable once per block"
        );
        lastBlockNumberCalled[user] = block.number;
        _;
    }

    function SAFU_TOKEN(address _admin, address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "nothing to transfer");
        IERC20(_token).transfer(_admin, amount);
    }

    function setManager(address _config) public onlyOwner {
        peaRouter = IPeaRouter(_config);
    }

    function setNFT(address _peaToken) public onlyOwner {
        peaToken = IPeaNFT(_peaToken);
    }

    function setERC20(address _peanToken) public onlyOwner {
        peanToken = IERC20(_peanToken);
    }

    function gemMultiple(uint256 _amount) internal {
        uint256 totalFee = peaRouter.priceKey().mul(_amount);
        if (totalFee > 0) {
            peanToken.transferFrom(
                _msgSender(),
                peaRouter.feeAddress(),
                totalFee
            );
        }
        if (_amount == 1) {
            peaToken.gem(_msgSender());
        } else {
            peaToken.multiGem(_msgSender(), _amount);
        }
        _generateKey(bytes32(block.timestamp));
    }

    function buy(uint256 _amount) public {
        if (Address.isContract(_msgSender()) || _msgSender() != tx.origin) {
            revert("reject");
        }

        require(_amount > 0, "reject: 0");

        gemMultiple(_amount);
    }

    function crackGem(uint256 _tokenId) external {
        if (
            _msgSender() != tx.origin ||
            peaToken.ownerOf(_tokenId) != tx.origin ||
            peaToken.ownerOf(_tokenId) != _msgSender() ||
            Address.isContract(_msgSender()) ||
            Address.isContract(peaToken.ownerOf(_tokenId))
        ) {
            revert("reject");
        }

        uint256 fee = peaRouter.feeGem();

        if (fee > 0) {
            peanToken.transferFrom(_msgSender(), peaRouter.feeAddress(), fee);
        }
        uint256 rnd = random(privateKey, 4);
        uint8 level = uint8(parserLevel(rnd));
        peaToken.crackGem(_tokenId, _msgSender(), level);

        _generateKey(bytes32(block.timestamp));
    }

    function parserLevel(uint256 _random) internal pure returns (uint256) {
        if (_random == 0) return 1;
        if (_random > 9999) {
            return 1;
        }
        if (_random > 9799) {
            return 5;
        } else if (_random > 9499) {
            return 4;
        } else if (_random > 8499) {
            return 3;
        } else if (_random > 3999) {
            return 2;
        } else {
            return 1;
        }
    }

    function adminCrackGem(uint256 _tokenId, uint8 _level) public onlyOwner {
        peaToken.crackGem(_tokenId, peaToken.ownerOf(_tokenId), _level);
    }

    function random(bytes32 _seed, uint256 _length)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.timestamp - block.number),
                        _seed,
                        seedKey,
                        _length,
                        keccak256(abi.encodePacked(msg.sender))
                    )
                )
            ) % (10**_length);
    }
}