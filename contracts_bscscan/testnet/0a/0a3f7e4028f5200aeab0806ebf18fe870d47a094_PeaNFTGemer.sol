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
    IERC20 public peaToken;
    IPeaNFT public peaNFT;

    bytes32 private privateKey;
    bytes32 private seedKey;

    mapping(address => uint256) lastBlockNumberCalled;

    constructor(
        address _peaRouter,
        address _peaToken,
        address _peaNFT
    ) {
        peaRouter = IPeaRouter(_peaRouter);
        peaToken = IERC20(_peaToken);
        peaNFT = IPeaNFT(_peaNFT); //NFT
        _generateKey(bytes32(block.timestamp % 1206230900));
        seedKey = bytes32("PeaNFTGemer");
    }

    function SAFU(address _admin) public onlyOwner {
        payable(_admin).transfer(address(this).balance);
    }

    function generateKey(string memory _key) external onlyOwner {
        seedKey = keccak256(abi.encodePacked(_key, 'COVID05092021COVID'));
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

    function setNFT(address _peaNFT) public onlyOwner {
        peaNFT = IPeaNFT(_peaNFT);
    }

    function setERC20(address _peaToken) public onlyOwner {
        peaToken = IERC20(_peaToken);
    }

    function gemMultiple(uint256 _amount) internal {
        uint256 totalFee = peaRouter.priceKey().mul(_amount);
        if (totalFee > 0) {
            peaToken.transferFrom(
                _msgSender(),
                peaRouter.feeAddress(),
                totalFee
            );
        }
        if (_amount == 1) {
            peaNFT.gem(_msgSender());
        } else {
            peaNFT.multiGem(_msgSender(), _amount);
        }

        _generateKey(bytes32(block.timestamp % 1206230900));
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
            peaNFT.ownerOf(_tokenId) != tx.origin ||
            peaNFT.ownerOf(_tokenId) != _msgSender() ||
            Address.isContract(_msgSender()) ||
            Address.isContract(peaNFT.ownerOf(_tokenId))
        ) {
            revert("reject");
        }

        uint256 fee = peaRouter.feeCrackGem();

        if (fee > 0) {
            peaToken.transferFrom(_msgSender(), peaRouter.feeAddress(), fee);
        }
        uint256 rnd = random(privateKey, 4);
        uint8 champ = uint8(rnd % 4 + 1);
        uint8 level = uint8(parserLevel(rnd));
        peaNFT.crackGem(_tokenId, _msgSender(), champ, level);

        _generateKey(bytes32(block.timestamp + gasleft()));
    }

    function parserLevel(uint256 _random) internal pure returns (uint256) {
        if (_random < 7500) { //75.00%
            return 0;
        } else if (_random < 9200) { // 17.00%
            return 1;
        } else if (_random < 9800) { // 6.00%
            return 2;
        } else if (_random < 9970) { // 1.70%
            return 3;
        } else if (_random < 9999) { // 0.29 %
            return 4;
        } else {
            return 0;
        }
    }

    function adminCrackGem(uint256 _tokenId, uint8 _champ, uint8 _level) public onlyOwner {
        peaNFT.crackGem(_tokenId, peaNFT.ownerOf(_tokenId), _champ, _level);
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
                        uint256(keccak256(abi.encodePacked(block.coinbase))),
                        uint256(keccak256(abi.encodePacked(msg.sender)))
                    )
                )
            ) % (10**_length);
    }
}