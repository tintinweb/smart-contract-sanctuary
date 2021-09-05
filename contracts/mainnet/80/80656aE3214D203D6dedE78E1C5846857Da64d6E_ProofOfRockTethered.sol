/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.3;



// Part: ERC721TokenReceiver

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///         unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4);
}

// Part: EtherRock

interface EtherRock {
    function getRockInfo(uint256 rockNumber) external view returns (address);

    function rockOwners(address owner, uint256 idx)
        external
        view
        returns (uint256);
}

// Part: ProofOfRock

/**
    @title Proof Of Rock
    @notice ERC721-ish contract where token ownership is 1:1 pegged with ownership of EtherRocks
 */
abstract contract ProofOfRock {
    EtherRock public constant etherRock =
        EtherRock(0x41f28833Be34e6EDe3c58D1f597bef429861c4E2);

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(bytes4 => bool) public supportsInterface;

    string[100] tokenURIs;
    address[100] tokenApprovals;

    mapping(address => mapping(address => bool)) private operatorApprovals;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        supportsInterface[_INTERFACE_ID_ERC165] = true;
        supportsInterface[_INTERFACE_ID_ERC721] = true;
        supportsInterface[_INTERFACE_ID_ERC721_METADATA] = true;
        supportsInterface[_INTERFACE_ID_ERC721_ENUMERABLE] = true;
    }

    /// @notice Count all NFTs assigned to an owner
    function balanceOf(address _owner) public view virtual returns (uint256);

    /// @notice Find the owner of an NFT
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        virtual
        returns (uint256);

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        _transfer(_from, _to, _tokenId);
        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "Transfer to non ERC721 receiver"
        );
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    function approve(address approved, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not owner nor approved for all"
        );
        tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @notice Get the approved address for a single NFT
    function getApproved(uint256 tokenId) public view returns (address) {
        ownerOf(tokenId);
        return tokenApprovals[tokenId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Query if an address is an authorized operator for another address
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[owner][operator];
    }

    /// @notice Concatenates tokenId to baseURI and returns the string.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        ownerOf(tokenId);
        return tokenURIs[tokenId];
    }

    /// @notice Enumerate valid NFTs
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalSupply, "Index out of bounds");
        return _index;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(to)
        }
        if (size == 0) {
            return true;
        }

        (bool success, bytes memory returnData) = to.call{value: 0}(
            abi.encodeWithSelector(
                ERC721TokenReceiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        require(success, "Transfer to non ERC721 receiver");
        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return (returnValue == _ERC721_RECEIVED);
    }
}

// File: PoRTethered.sol

/**
    @title Proof Of Rock: Tethered
    @notice ERC721-ish contract where token ownership is 1:1 pegged with ownership of EtherRocks
 */
contract ProofOfRockTethered is ProofOfRock {
    constructor(string memory _name, string memory _symbol)
        ProofOfRock(_name, _symbol)
    {
        totalSupply = 100;
        tokenURIs = [
            "QmPJ8qzTuu4ThCJNDxa7ib1DUYhEbAPzMUpasinnucC5AH",
            "QmXNSt14kaGKauW37VxLShLSqfvLyShzBnVBmbhXbJdci6",
            "QmdtQsrEzrgztRYuKvpnYMxcYLfQxS59x9M5fBQVGvSx3q",
            "QmVwExvwgZuKDavcTGEYLi8wrSEUerRXcSD7NEfbzZgFLE",
            "QmekTo6LMCVRKrdrHPqiMhYwU3uiCqZgVtjjtTRmTk4w5v",
            "QmadAqBoMXm7AdLXWNsLqyBjwEUh9XrEALftKWSVqyb2Ws",
            "QmZi6WxyVEMLzRA6bm51iDNw9qTxbieEJDzAkYbr4b1DMo",
            "Qme1fuKKBUFsGzzwBRDjDtnrfiUHP9zkb3Jgi9ojKk7Hv5",
            "QmRucC5Ux7FvmWCScTKLxCiorxXY8daCyTPx3tGZDRRccb",
            "QmYaNk6gGbQ9QoabN9jurwPQ5py7GjW8M5WWJdwKmzvL9Z",
            "QmYojyCWKPM9e2xYj54H7c2bD67Nbbx2mVjLQZHo7P4WhS",
            "QmVPgPH4yZizyjVHd3YpAHwxQHP5jXfsg3UqnbAWXs5v7d",
            "QmYrzkgg4UVrCuxeYn5ij8Pmygof2rhd7BqrMgTNPBnQ8d",
            "QmTzAzj93EDEMq3jmoRPFV4fsB5rTQHNBFy9EMTSEPh5QA",
            "QmcjQMD9LSZinXWVFqmMdPXXiwqiTUpgSc8pyWRE4QvfuZ",
            "QmfCP8PT934BR4FVsSzsxze8NfLMepwNFb2ZYih4Gz4ZJt",
            "QmNxr6zrdeFZuAdQFmWevQ9BdVuboZevxzrhMcPQRnCjTb",
            "QmUXgtKx6tVvKk1aqDD5aZwB7C5ct3R1tS7m45kgKsgKf2",
            "QmXhvWC3xTBUFe85GLWrqUNay347EVD7hYKc1aBHoyr2Co",
            "QmRUN2R6wLNCfxAz3zK3bdnCYkT4EzGmSQMqLaKaAF1w6G",
            "QmRChgYU8CraSPB4YU1HN9RXuTmx7USR3LPuCHArv5EAGG",
            "Qme5gCUYKxQaqrAEq428dDMpt1neBWkaZnD7YTKxVGwFxU",
            "Qmf8Db6UE3sdcexkG8eK3p88p3bTbL1tSsVFiPTzKuUwdQ",
            "Qmb8C1sfx8cvmo5E5CENzZX4WBJyJdYbf5zVgcfsUH9v1m",
            "QmVdgUU4VBSp8goWBxgAj7zQuCNBYRk1kCkL5a59z2QHbE",
            "QmU3iddwTtYhQUBvxJHmrH4tB71qo7DnvJ9yoEwJfipUK3",
            "QmWH894qumXwCupitw4U1YQ7P6rhZhxAjJSSCj9Jm9tZu7",
            "QmR2JTwZLTurjFfL2nrqVuFJBo9TvnerrybGuDsA4uv3EP",
            "QmdAWM9HnxehbX1mEHN6FAPTuksNrZjEVhKHoSRtWYxYct",
            "QmTLi4PMR9oas2Rtq3LjXxGfFKbVqFGxh7xrQd98tZxHWp",
            "QmcVWASAA2oDVmUyiP1pLMtbAQx4MimWEJZLjxgQmZv9cW",
            "QmY5cmDU3VuRkJV8hA1wRcvxK6ECLD9nmsvQXqV69MUFyg",
            "QmNi2Th3LdhyeccUJZNHjVRBKvpB9MFYJi26w9rZiRwJkT",
            "QmfFEoTsJCvzuRE8z184sTEzYdEtDkaFtDuzAKT5QWMKHo",
            "Qmf5HTTWV9EST9J4QMXM5VRpLVw9NdQLxgPJYGp35NseZz",
            "QmbpSpiEKzXwjq41MeCxqPfMkdt2xRNHGQ26uKRyekwuQ8",
            "QmZmHDrodoc1KvZwb2SzVo6Bu3zouWogmEQG9GMGrFLuAR",
            "QmdvxaEqZA5tihnm2kQ3maPq6njZ66EXRzVamYnHaPjipb",
            "QmRcdQbuuTyc2wp6jsbJog7Cf31WkXC6LptXs9VgErjBPK",
            "QmSkGRL66jKDqwVwvU2vGsGtgq8Ejy7LdGy7Fyc8RsuZzC",
            "QmXnwPkxfvSuTFwV9Wk4ibVo9ci8qKmjmMXWjTJXf8pgTs",
            "QmcdrEVE5KKTCU59gCuFJ87HijSovzdpBF8USmubhd4d6z",
            "QmQt7KDGaPVxxzFiuvKpfdSjDfbT9ATHdK7JY1EEdZzT52",
            "QmPijpreFELWBJnxKd4F9gekV4JSjM27szw9VSKC6GxoiX",
            "QmU1Db1Ft4gXLkdHNCw7uM98dLpfVq39b8aK1oLWMZN7QT",
            "QmaynTAHbVGg2ERcDbpnBukoFgwL8f4eKDDVuBYfRFi4Qu",
            "QmWnLxpYCG4HmCCiULdBSpayqw3JtfJvz4gkTuobzeVLQ1",
            "QmSWERGitRfcD5ABk322z8RGf2dWS5MvJi3wisHX7dMknN",
            "QmdBxsrXs1sK1btiQKybveyLTqeG2kHG1xuKt6c6piEHNF",
            "QmVmMoYeBUc9o1NFA5ucDwmi2BGpbaEoCQ2ARBGC7LP6jR",
            "QmSupSUfBfnyCqoBHzCnxkSWRzqHoJRAQJjWYDzg5Jhb6C",
            "Qmd2ZuNVGSTbj2qBfLSUkgcKTcfWgMpgtbyhkdJrPQSgm8",
            "QmNoTWLsm6BYPsyVRDdKjhMPBsMJ8f2TZQmKtGk5fu7tWz",
            "QmcFmPHiGmoYjZ5nrj2EnkvcgNgT6e8oADyBZ6Gk6SE8Y9",
            "QmdcSqkNo5Txp3hoZWftHmt98kenvTWAuKjXPHJfSsv3RC",
            "QmU3eBA5q7b94rUThWARPvMobedNRSZ7ueBxCTGZmzv1nR",
            "QmSbmXujufQtFTi6K2SAcQ8etQSS2GtY7gf2RPYfyjo1nv",
            "QmVmSeqorghs6omNbRSnrBFjWun4qxrZ8buEkyMruuRbpB",
            "QmQT3gfDXYvk8iix1iv68UpoCJbpnsBay7Lpf5X67mGzRV",
            "QmeraW9Drh6VuaLk1ev7xpTDqEzh5tHFjd5CttMC57xmVX",
            "QmQ4ABH8SLDrLaZiHhebfbQEUudcgkvdVAvWUQyCE46Yqo",
            "QmRqJimbHkndUmYG1pxMFYMWp51P2qg9KdorEKZhU6XDt2",
            "QmPwzA4UKaQQeJmjtfXdaVhUodAz3TvA5pkympumeU4BEF",
            "QmcgJWLMF7q3eJScKrD9F6cqg6Fa4MivJCcKaU7SQYhYhM",
            "QmRXKHKvnBhKyEteGxw59DLqsouTPBYvTuHyHSmbxCLtND",
            "QmTVRZH86PEF2MDucSH7grQip9i9fGbLoT5euSW5jG1mis",
            "QmP5r2yf19BJ4VzzL9Z5Txh7TcZcZr2brGWyQY14mEABG8",
            "QmaTryHgQ6ARUJAUedTnPy97njS642zm3Vy6xjfLFEX32Q",
            "QmfDVU77wCGtebMxgxTjvFd2HDiskv34H3xBvLyJUAQNJa",
            "QmXYtx1Xks3mvDNLweSkCjwrhQssUW1afK9vXKHciBLNMn",
            "QmRkCenqbXhKxykcBDmuvzWKxnmuvB93vSmUeG5YSrDj6e",
            "Qmasg7UKJvdaTDTNxZ54w7gAVyaK1YDNy1vxuqCoX52W6q",
            "QmX8JyrSE2BdLsenHKdQV84tFWSzDX5LfmWnfgpNfQp9AX",
            "Qmf9ydFPcJXwqYU1NPUyJ3RHM5jZCeTkJrntjA6DBmTb7C",
            "QmTSzAeyv9a6oW3ZZ8sP9WogQWBqFWHd3oGFudMabvo6xX",
            "QmQrXSFQiW3rF4iztos6Rdy5R8PCpRAzLndaBQ9MYm5SNL",
            "QmZQhsWMDtQnJnGWACaZAhm449cbKQonG4XWhQNeMBtNQa",
            "QmQMwHXwLCHnh9DT5xXGRrt8SLTQB1yEmmVKuE2EfHjT1r",
            "QmVwrxXGsPx5QU4RQ7H5eY67GkUpCa1tukmZ8ARZVqzBR9",
            "QmY22M4fAR4xabVeJeWF7wPx9PiyCLYXuwo1ZHqxrbtnuz",
            "QmV8DPURTE9mxnMnUU97LsCveYj7EHJQwcKGeDacGHtRuP",
            "QmTogHdDApN1kTDEtAYbs43m9jRDc3JNvxSWjgkQrPV6ja",
            "QmTKSW2PzUpoAj6oiVa7tSh3pzJvpJU6H2YrTLSx746D9f",
            "QmbQjggJpXPkCmLYHt46VuZ6hSPvS51WcXBRvvy6ezzjGW",
            "QmRV35WjZwvdaBoPVr1YX8oqLHxnDcYfNXju7QvWXCV7h9",
            "QmTbzjS9RUajbKfELMDyYTpoopi8VTgwhYRefSect6RowM",
            "QmZus6AWjsVAsinnGimJ1sTfFRaQn4R2abupHY8DimNcdc",
            "QmVawAxirBmd56DNv7RuxP1m4m1UNR8goCt9H9H1ME3PDc",
            "QmThmqdMEAyyE7rdN7uE1AgQKfM4cRiWkTDWs1QGuqDBWe",
            "QmP9MtgGpANWKujcWUpRZkANDNhcfM4yTncQMzAeNZ34N8",
            "QmajtUPkX3EzfsRq9EwQTYo88DNfCnKHVWE1po1dCc7JGL",
            "QmaLqdQs1X3AKs2BRxZUxJjbVJqtXLfC1SycJysafbW8Tp",
            "QmUVxfFwRbPGxY9sM65QeRvg4ng4Vt2hsCMSL6kGBTZbtg",
            "QmdzVD1XC4D7ydPa2dP98WmDpvkcxizApebc1ujJvwzThb",
            "QmStSzhebV5cvokQ6Q3PRgnHLfciiMFPbh9DMnCvHZ2KXG",
            "QmW8zFv1CFqDnqxjBnR69db5Gj54RnYrim4qqwtqZ5kMyC",
            "QmahcvNu6XbtwDLHz45iYqrzf9qzxTRZ4qtn9o7JaZ8VBv",
            "QmaMvgiHEZSEnU9THJPwAthYNbQuwSdZkPqiC3FiwnRJfX",
            "QmP7FQNXYhe5eWWQEHRT4SihCTF7dZbv3LSMBtXY3HyBto",
            "QmRxC4a7Uo23KCYVqUxsHmimKA1wYTukJ6CGRgm8aCZ1Gd"
        ];

        for (uint256 i = 0; i < 100; i++) {
            // We must fire this event once per rock in order for OpenSea to recognize
            // the NFTs. When an EtherRock is transfered after deployment, OpenSea
            // will notice the change in ownership of this NFT within 24 hours.
            emit Transfer(address(0), etherRock.getRockInfo(i), i);
        }
    }

    /// @notice Count all NFTs assigned to an owner
    function balanceOf(address _owner) public view override returns (uint256) {
        uint256 index;
        while (true) {
            try etherRock.rockOwners(_owner, index) returns (uint256) {
                index++;
            } catch {
                return index;
            }
        }
    }

    /// @notice Find the owner of an NFT
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (tokenId < 100) {
            return etherRock.getRockInfo(tokenId);
        }
        revert("Query for nonexistent tokenId");
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        revert("NFT is attached to rock");
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        try etherRock.rockOwners(_owner, _index) returns (uint256 tokenId) {
            return tokenId;
        } catch {
            revert("Index out of bounds");
        }
    }
}