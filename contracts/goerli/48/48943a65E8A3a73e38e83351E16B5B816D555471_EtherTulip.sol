// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// This is a revised version of the revised version of the original EtherRock contract 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2 with all the rocks removed and rock properties replaced by tulips.
// The original contract at 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2 had a simple mistake in the buyRock() function where it would mint a rock and not a tulip. The line:
// require(rocks[rockNumber].currentlyForSale == true);
// Had to check for the existance of a tulip, as follows:
// require(tulips[tulipNumber].currentlyForSale == true);
// Therefore in the original contract, anyone could buy anyone elses rock whereas they should have been buying a tulip (regardless of whether the owner chose to sell it or not)

contract EtherTulip is ERC721("EtherTulip", unicode"🌷") {
    struct Tulip {
        uint256 listingTime;
        uint256 price;
        uint256 timesSold;
    }

    mapping(uint256 => Tulip) public tulips;

    uint256 public latestNewTulipForSale;

    address public immutable feeRecipient;

    event TulipForSale(uint256 tulipNumber, address owner, uint256 price);
    event TulipNotForSale(uint256 tulipNumber, address owner);
    event TulipSold(uint256 tulipNumber, address buyer, uint256 price);

    constructor(address _feeRecipient) {
        // set fee recipient
        feeRecipient = _feeRecipient;
        // mint founder tulip to yours and only
        ERC721._mint(address(0x777B0884f97Fd361c55e472530272Be61cEb87c8), 0);
        // initialize auction for second tulip
        latestNewTulipForSale = 1;
        tulips[latestNewTulipForSale].listingTime = block.timestamp;
    }

    // Dutch-ish Auction

    function currentPrice(uint256 tulipNumber) public view returns (uint256 price) {
        if (tulipNumber == latestNewTulipForSale) {
            // if currently in auction
            uint256 initialPrice = 1000 ether;
            uint256 decayPeriod = 1 days;
            // price = initial_price - initial_price * (current_time - start_time) / decay_period
            uint256 elapsedTime = block.timestamp - tulips[tulipNumber].listingTime;
            if (elapsedTime >= decayPeriod) return 0;
            return initialPrice - ((initialPrice * elapsedTime) / decayPeriod);
        } else {
            // if not in auction
            return tulips[tulipNumber].price;
        }
    }

    // ERC721

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory bulbURI = "bafkreiamkokggzkchkosx5jvz6fduzwcn7qugkp7pytmk327sblrtwa4ze";
        string[100] memory tulipURIs = [
            "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy",
            "QmfWRhjNqyXyqEnarRRq5whaBmTm9sKJU7TxWPD39NX4TP",
            "QmX2tgEKCBgRYHPnUAm8AdNFzDJGhjRZ4ZkvQZNmgKUe2p",
            "QmSeAU7SynbUPNPNWeu8wTyV5nJGLSFk1VdequQxbvLggg",
            "QmapgjCNbJmXm1bRNFiQh5ozhMTEBwmhpukpHBiqWFMdDa",
            "QmeYh9ZkRe6ZvdFkRaTjqkdBUF6FwCtEJgAnihXj4j3v13",
            "QmQRk4TozeBtPWnHMtq3Am36LMf33PsJQyzNPTaBWHKNFS",
            "QmUSXJRyhTRxz6TA6MseGqBERXPPid3x8PVkkh99NoFv9S",
            "QmSEwpg5C2dfgxywDeCmtUVaUdKiLFKXQK8d9KCku3SF2Y",
            "QmcQJrWyt1TUjsbjZSjcD4Vz8nKsy4VseJsB8N7EvhSUPJ",
            "QmPb12GN3pcvL78NVQ6FK9AE252ChBK8gQMCzUjez7prC7",
            "QmfGXgopgkAiERmtt2inMuwvaajKv8uUow2WjVuJd8n8Cg",
            "QmRpt7sGKRSxcdpnkdLEdrQZyuMyYgoqez6mYumTdAkmbo",
            "QmSqE8AjqsiHx5baZ2M4p6mjC5Va35F65yDbkRebFaHGZu",
            "QmQ6wZHRCaFHafhyqGAK3638biAk6tz56DCAK2BLQKPTct",
            "QmT8ezQ4nuESWYMzcfbb6kcfESDDyeK2CBYp1uaRQo9xLd",
            "QmZr1z7cCTXRqYWvPSatcGZwJqSt8j6hsMxLUJBQMbnVnr",
            "QmTSuh4gznWdw3STbBVG1Ve1jynHHLpfFcdgFwJi4nqktD",
            "QmRpCGbX5eFbtDehnhatdtp7a1kzmgnkAZSJubsD5Hx7Hh",
            "QmUUDST3T2oHHrf7Sm4AbVxsh46Mt42XyV6S1AMVgFWM88",
            "QmY62Pt1923mPKaJkSLyYoSWCGYbLiyxWQoZYaMHPE8FNF",
            "QmZdDjcsxzS7vQkQiiRmtfDC5S5CAvHRELyMsAF1cPrF3Q",
            "QmQRZ6emrZyepPGSFfGXUAiHJYVRJaKU83Qyr7KcXfNsbf",
            "QmfCDeQvQJ2CwKA5VNie6LC5Ny63VdL7uy7UaZwmoJ5Cmu",
            "QmV585E22k9gJjcBeZNtYdDmoi6yfr36M9yVLdiQP3LxAD",
            "QmeNqqxdMN5AutjZWeqLQFJzfM6Vxvyi9mBHHKyEWv5r31",
            "QmX9ZoDYo5ut3icFft1UugnmkyPbZhuYYpg8yPMJzYFftU",
            "QmRJJLP1ZvPLkyenD7jx7eC798ndeFQyv22rsCaSViLN6k",
            "QmRbt7LFyAAuCMnv9sAhKRtUrUMSrSQYuFPtPNhpSsjgmq",
            "QmQNy8Y83KonKfB59kzhvr9eQ4DjC77mJEjuPUpNRKTiKK",
            "QmZiUEGNKZwQZqrKnDV698hjxT2E4vLuq16Ps3potVDAo8",
            "QmQUxDwfRXyErr8pUcfKaxjCJwUj7SiE9DLrrJHqL9wCxa",
            "QmWrkTnGULvc9m7hUub5ss6H1oTfixfixjdgkbrbvxpKNr",
            "Qmd8eNduEprDi1JX8NUwDXDBDuXcGPmBM3fa1xH5yuMf8d",
            "QmYKXfA6LsVa28Xn2fLz435Smzm4N6FeJ1k3oVhrmvnAJF",
            "Qmf6xbzaQ1P6StboKGApSkuDoXeB5cZ61wotLT5Lz1UR9G",
            "QmZVE4KyoFViMApkgjrqFDnh15HEmXrmXcT9fBnNwhrByo",
            "QmPWihwusF9ZwtPiXAf87MWD9cA9gENjjVAHPMtLvDBC12",
            "QmXB34jHAPb7QfRVVnXqpynWaLsGMT1u5a4ZyJWwPRFE7e",
            "QmZPSj78qzByt6UCFcamUtFJV52yhT5zBnWH63drhFDftf",
            "QmVVKjGCh1xjTC9dq3ZUJnZLeJJoQrRJhbT2Jfb52NnsA7",
            "QmauiTLCD6ZBBqZnG1XnkEtgvxfxSAN3YaKtGX9Y4xmNvN",
            "QmVu9UaQ6HzMRSNh4kH3Chn1yr7zXEg3yrfDaAwJKfvynA",
            "QmexUh6jw2ThRr7T8c4DkAhU9QYRzdH8AqAQHxiFrvf9Wi",
            "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ",
            "QmSdPufB8nFjNnexJmkmNva4HrtwNHLDR5LmzkvWA5755d",
            "QmYebUrncSKgvoGXmWo4WyYqnd7B2sE7fgeTj81s8hKann",
            "QmPmFrB8afYZoq2EL3tQ71FiauxkKke5ELDtxNEAXbBe3U",
            "QmQ5NiJuZNoyv6xVm7wZEpvNanqLgajknz1s2EdnEh5YDt",
            "QmaCj77AeNV7F3YE8KTLk6ijXJkqLRZrqoomAcpks1ZpC1",
            "QmUtFQ2NaA1zoBHoASwgaFsn2DED2ZjSR4D3wvt3Y1kTcG",
            "QmZB4qQD4d2uBiSZoUQWpFSRf63FQvkMaSjFzP6CnNgTH1",
            "QmQrm4mw4tYzsNMHd2wvhyqJfZ4u1FosYTr2Fmc9v1KUzt",
            "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg",
            "QmczFxFCZEWAsiFCPdsdovKWMqrhAk1zfXM6HS66zFzA4P",
            "QmQDceMyrYftARLBr4QANf4L1Wi4DnCAzrck6JnJ5cKLs2",
            "QmQogFCB14WgPJyoPpmPScRLNynRpGAK9GpbK25Uh9u7pf",
            "QmPGdKY1W7XzCasRyQ6ePyzM2vWjwbHqvUGnZY5BhZus5C",
            "QmaAbvGDB22Ycw7Xn1hapGuYDESvs91jWQdqLGJDiZTLvy",
            "QmbqsPb7SdUbm1TdvgWeh1HytT6ioitJ9mkzKZRsZt1iMU",
            "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ",
            "QmVbZHhThcDrM37P3yge9PyzTVpeuD5EZBzwzqJukuW9CX",
            "QmRruwFh2qGP4vZYsYRgDgScUBzBSWSf61XsrLBi2Y7LZi",
            "QmTjUE74LVF5eUEhSmh4yVSLUwzHdwD1RwhE6MeouXzksn",
            "QmTFS2tozPcH6BApzwhRW1bCVmsLPFFVcMRKHfaTADH87T",
            "QmRgYA3poAMcfDa1qwW9ZbUpy5qSKEk6DYTMwtvStuSM4y",
            "QmZ5eRoQ5qVTAmu41WQkjBemk4yS6nSXJjRDAeG8QmZWjJ",
            "QmcK2YWM3cN7MbcDcL1Wa3uvHhdkeY3gUQjAGfqDpvZSuR",
            "QmX7RSKvKDBKBLJ1zY3ohAwpsCkxp9bwejmKTdE8Lx83eQ",
            "QmWgU93KrKzw7JUBzgt5zmNEfwGrwxud6nS5dZTBPnTcLZ",
            "QmfEpi6bvcaHYgDcvGEBdqavgqvctg8NsVxY6bkfA4d8EE",
            "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg",
            "QmPz7X7YwS2HDqTtEa4LqaUQF3geEvmgfQd3LvdaEw6zFH",
            "QmfLa3r4J5DzZ85KzQRbX2sxDLqTcxiTR6gkjp5Chz3KSr",
            "QmYeW9C2zLxoB3imWXLxXKXaRqopWvCbN8WhakAPauE3TK",
            "QmV4CPhqmmyssCqxLU6f6i4jxhaxbkzoiojNkPgZf79Hra",
            "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV",
            "QmcK2YWM3cN7MbcDcL1Wa3uvHhdkeY3gUQjAGfqDpvZSuR",
            "QmTHLruP6iHriHqqw6oPX6Tsy4hiVzT7MQsUpoaubAqsij",
            "QmcCaMjtstUhrv5Utm52NQikLhT4FLu9DWsA6vWTcwSakp",
            "QmYKoXs9hHJy2aZn3dF35BFhmNzr9fz1YhfcgQRs46SynK",
            "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV",
            "QmPqpQBWWTb8DP6bmXWgZsXUUh6Lqj2ShMXHC2rudgzzDQ",
            "QmW1kvaXxDERZcBYyc1ZtzVVTno1iHr5sWGLHPEv6VnRM2",
            "QmYuL7t35d6UZgqeFhXsueFm7V5KQEeyuLcEVgmr11i1Kb",
            "QmP8Ckrb9BvDWXLXoZKoRJvfRhs5U4fS8NaTbEhvvGKzhV",
            "QmZGTsrecqQyNWzh2SSVhsqJsGHwVT2sVEBFcNMnwV73df",
            "QmX9ANT6HZGXegt9p5fWRfzv6Bzve2agNGA7LtDzngTJAg",
            "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy",
            "QmT5J37y58QSqDAJhtfT3NKfh2dxmdgDweBrcpLiedkPEH",
            "QmTRCus34ftngddGLpx3e3gEzWvzoF3NHrK2rc89LNWTyc",
            "QmatWTce4vojinsc5vt7U7woeqYQ87Lhn1NABHx1MYmnNZ",
            "QmeNqqxdMN5AutjZWeqLQFJzfM6Vxvyi9mBHHKyEWv5r31",
            "QmS8q36mainSQneGonX9fFrWB15B7A9HC8o3vkwkCSrqUA",
            "QmWG3mGDQLFuVmajqsiT2nCvmEeU2qgCCCQyG3f4E53svi",
            "QmXMfHnX7MgLcA7Bbj4Bpawe4b5EPg7B1McLaf4XHamq1z",
            "QmS5Pb4i72JfSsip3PPCELf9Bu3ygce9D2kGS2BEx9PPGy",
            "QmQJbKHjvhZtbiaFWJiJ1DxGQ6gyxZxTzKp6VxR95sTXUY",
            "QmV4Bvz7URJa3Rzfp5sBmMQt4FFmWE6Dsuvg6neWpRsEBe",
            "QmX4WEC3Y41mFV4sNNiV6QyTqkRhmu1NnF8ZcQBHZiFVED"
        ];
        require(tokenId < 100, "Enter a tokenId from 0 to 99. Only 100 tulips.");
        if (tokenId >= latestNewTulipForSale) {
            return string(abi.encodePacked(_baseURI(), bulbURI));
        } else {
            return string(abi.encodePacked(_baseURI(), tulipURIs[tokenId]));
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal override {
        // unlist tulip
        tulips[tokenId].listingTime = 0;
        // emit event
        emit TulipNotForSale(tokenId, msg.sender);
    }

    // ETHERROCK

    function getTulipInfo(uint256 tulipNumber)
        public
        view
        returns (
            address owner,
            uint256 listingTime,
            uint256 price,
            uint256 timesSold
        )
    {
        return (
            ERC721.ownerOf(tulipNumber),
            tulips[tulipNumber].listingTime,
            currentPrice(tulipNumber),
            tulips[tulipNumber].timesSold
        );
    }

    function buyTulip(uint256 tulipNumber) public payable {
        // check sellable
        require(tulips[tulipNumber].listingTime != 0);
        require(tulipNumber < 100, "Enter a tokenId from 0 to 99. Only 100 tulips.");
        // check for sufficient payment
        require(msg.value >= currentPrice(tulipNumber));
        // unlist and update metadata
        tulips[tulipNumber].listingTime = 0;
        tulips[tulipNumber].timesSold++;
        // swap ownership for payment
        if (tulipNumber >= latestNewTulipForSale) {
            // if new, _mint()
            uint256 _latestNewTulipForSale = latestNewTulipForSale;
            // update auction
            if (latestNewTulipForSale < 99) {
                latestNewTulipForSale++;
                tulips[latestNewTulipForSale].listingTime = block.timestamp;
            } else {
                latestNewTulipForSale++;
            }
            // mint and transfer payment
            ERC721._mint(msg.sender, _latestNewTulipForSale);
            payable(feeRecipient).transfer(msg.value);
        } else {
            // if old, _transfer()
            address seller = ERC721.ownerOf(tulipNumber);
            ERC721._transfer(seller, msg.sender, tulipNumber);
            payable(seller).transfer(msg.value);
        }
        // emit event
        emit TulipSold(tulipNumber, msg.sender, msg.value);
    }

    function sellTulip(uint256 tulipNumber, uint256 price) public {
        require(msg.sender == ERC721.ownerOf(tulipNumber));
        require(price > 0);
        tulips[tulipNumber].price = price;
        tulips[tulipNumber].listingTime = block.timestamp;
        // emit event
        emit TulipForSale(tulipNumber, msg.sender, price);
    }

    function dontSellTulip(uint256 tulipNumber) public {
        require(msg.sender == ERC721.ownerOf(tulipNumber));
        tulips[tulipNumber].listingTime = 0;
        // emit event
        emit TulipNotForSale(tulipNumber, msg.sender);
    }

    function giftTulip(uint256 tulipNumber, address receiver) public {
        ERC721.transferFrom(msg.sender, receiver, tulipNumber);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

