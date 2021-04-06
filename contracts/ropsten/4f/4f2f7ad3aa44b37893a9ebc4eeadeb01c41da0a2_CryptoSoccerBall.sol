// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721URIStorage.sol";

contract CryptoSoccerBall is ERC721URIStorage {

    // nb total of ball created
    uint32 nbBall;

    // address of contract creator
    address referee;

    // delay before you can steal a ball (2h by default)
    uint64 minStealDelay;

    // Mapping from token ID to last shoot timestamp
    mapping (uint256 => uint64) private _lastShot;

    // Mapping from token ID to master owner address
    mapping (uint256 => address) private _masterOwner;

    // Mapping from owner to boolean
    mapping (address => bool) private _alreadyMint;

    // Mapping from masterOwner to ballId
    mapping (address => uint256) private _haveMaster;


    /**
     * @dev The account that deploy this contact become the match referee.
     *
     */
    constructor() ERC721("Soccer Ball", "BALL") {
        referee = msg.sender;
        nbBall = 0;
        minStealDelay = 2 hours;
    }

    /**
     * @dev Everybody can create one and only one ball.
     *      The account that create the ball become the masterOwner.
     *
     */
    function createSoccerBall() public {
        require(nbBall < 2**31 - 1, "No more ball");
        require(_haveMaster[_msgSender()] == 0, "You already have a ball");
        require(!_alreadyMint[_msgSender()], "You already mint a ball");
        uint _id = nbBall + 1;
        nbBall = nbBall + 1;
        _safeMint(_msgSender(), _id);
        _setTokenURI(_id, "QmauiCZRfq8vmG3wSKcYNyJ8ZRLAM87KUoHGkj6VZmbzGa");
        _masterOwner[_id] = _msgSender();
        _lastShot[_id] = uint64(block.timestamp);
        _alreadyMint[_msgSender()] = true;
        _haveMaster[_msgSender()] = _id;
    }

    /**
     * @dev test if one user already create a ball.
     *
     */
    function canCreateBall(address user) public view virtual returns (bool) {
        return !_alreadyMint[user];
    }

    /**
     * @dev get the number of ball created since the beginning.
     *
     */
    function getNbBall() public view virtual returns (uint32) {
        return nbBall;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev get the ball id if user is a master of one ball.
     *
     */
    function getMasterOwnerBallOf(address user) public view virtual returns (uint256) {
        return _haveMaster[user];
    }

    function getMinStealDelay() public view virtual returns (uint64) {
        return minStealDelay;
    }

    function getReferee() public view virtual returns (address) {
        return referee;
    }

   function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;

            for (tokenId = 1; tokenId <= nbBall && resultIndex < tokenCount; tokenId++) {
                if (ERC721.ownerOf(tokenId) == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }


    /**
     * @dev return the master owner of a ball.
     *
     */
    function masterOwnerOf(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _masterOwner[tokenId];
    }

    /**
     * @dev return last shoot date of a bollon.
     *
     */
    function getLastShootOf(uint256 tokenId) public view virtual returns (uint64) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _lastShot[tokenId];
    }

    /**
     * @dev Change global minStealDelay.
     *
     * Requirements:
     *
     * - only referee can change it.
     */
    function setMinStealDelay(uint32 _newDelay) public virtual {
        require(_msgSender() == referee, "Only referee can change it");
        minStealDelay = _newDelay;
    }

    /**
     * @dev Give the master owner role of a ball to someone else.
     *
     * Requirements:
     *
     * - only current master owner can transfert this role
     */
    function offerBall(address to, uint256 tokenId) public virtual {
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(_haveMaster[to] == 0, "Destinataire already have a ball");
        address ballOwner = _masterOwner[tokenId];
        require(_msgSender() == ballOwner);
        _masterOwner[tokenId] = to;
        delete _haveMaster[_msgSender()];
        _haveMaster[to] = tokenId;
    }


    /**
     * @dev timestamp after you can steal ball. 0 if you can't.
     *
     */
    function stealAfter(uint256 tokenId) public view virtual returns (uint64) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address master = _masterOwner[tokenId];
        address owner = ERC721.ownerOf(tokenId);
        if (minStealDelay <= 0 || owner == referee || owner == master) {
            return 0;
        }
        return _lastShot[tokenId] + minStealDelay;
    }


    /**
     * @dev Anybody can steal a ball.
     *
     * you can't steal the ball:
     *
     * - if the current owner is the master owner
     * - if the current owner is the referee
     * - if the last shot was less than minStealDelay old
     */
    function stealBall(uint256 tokenId) public virtual {
        require(minStealDelay > 0, "Steal not activate");
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address master = _masterOwner[tokenId];
        address owner = ERC721.ownerOf(tokenId);
        require(owner != referee && owner != master, "ERC721: transfer caller is not master owner nor referee");
        uint64 lastShot = _lastShot[tokenId];
        uint64 delta = uint64(block.timestamp) - lastShot;
        require(delta > minStealDelay, "Theft too early");
        _transfer(owner, _msgSender(), tokenId);
        _lastShot[tokenId] = uint64(block.timestamp);
    }

    /**
     * @dev Shoot the ball to another player.
     *
     * Requirements:
     *
     * - only referee, owner master and token owner can transfert the ball
     */
    function shootTo(address to, uint256 tokenId) public virtual {
        address master = _masterOwner[tokenId];
        require(_msgSender() == referee || _msgSender() == master || _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        address owner = ERC721.ownerOf(tokenId);
        _transfer(owner, to, tokenId);
        _lastShot[tokenId] = uint64(block.timestamp);
    }


    /**
     * @dev Shoot the ball to another player.
     *
     * Requirements:
     *
     * - only referee, owner master and token owner can transfert the ball
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        address master = _masterOwner[tokenId];
        require(_msgSender() == referee || _msgSender() == master || _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        _lastShot[tokenId] = uint64(block.timestamp);
    }

    /**
     * @dev Shoot the ball to another player.
     *
     * Requirements:
     *
     * - only referee, owner master and token owner can transfert the ball
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        address master = _masterOwner[tokenId];
        require(_msgSender() == referee || _msgSender() == master || _isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        _lastShot[tokenId] = uint64(block.timestamp);
    }

    /**
     * @dev Destroy a ball.
     *
     * Requirements:
     *
     * - only master owner can burn the ball
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        address master = _masterOwner[tokenId];
        require(_msgSender() == master, "ERC721: transfer caller is not owner nor approved");
        _burn(tokenId);
        delete _masterOwner[tokenId];
        delete _lastShot[tokenId];
        delete _haveMaster[_msgSender()];
    }
}