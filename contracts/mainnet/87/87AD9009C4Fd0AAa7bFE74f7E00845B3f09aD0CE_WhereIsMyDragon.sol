// File: util\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: util\IERC1155Receiver.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.4;


interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// File: IWhereIsMyDragon.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.4;


interface IWhereIsMyDragon is IERC1155Receiver {
    function opt() external view returns(address);

    function get() external;
}

// File: util\ERC165.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.4;


abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: util\IEthItem.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.4;

interface IEthItem {

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;
}

// File: WhereIsMyDragon.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.4;




/**
 * @title Where Is My Dragon
 * In this Contract yoy can find all the ruleHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH!!!!
 */
contract WhereIsMyDragon is IWhereIsMyDragon, ERC165 {

    uint256 private constant RAG = 0x172 - 0x16f;

    address private _san;
    address private _frid;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))))) private _bor;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))))) private _lid;

    uint256 private _baskin;
    uint256 private _dolbur;
    uint256[] private _sagar;
    bool[] private _franco;

    uint256 private _gel;
    uint256 private _sic;

    constructor(address mon, uint256 tue, uint256 wed, uint256[] memory thru, uint256 fri) ERC165() {
        _san = msg.sender;
        _frid = mon;
        _baskin = tue;
        _dolbur = wed;
        _sagar = thru;
        _gel = fri;
        for(uint256 i = 0; i < _sagar.length; i++) {
            _franco.push(false);
        }
        _parabara();
    }

    function _parabara() private {
        _registerInterface(this.onERC1155BatchReceived.selector);
    }

    function opt() public view override returns(address) {
        return _san;
    }

    function get() public override {
        require(msg.sender == _san);
        _san = address(0);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns(bytes4) {
        revert();
    }

    function onERC1155BatchReceived(
        address,
        address fal,
        uint256[] memory cik,
        uint256[] memory hse,
        bytes memory cas
    ) public virtual override returns (bytes4) {
        require(msg.sender == _frid);
        if(_san != address(0)) {
            (uint256[] memory zik, uint256[] memory bol) = abi.decode(cas, (uint256[], uint256[]));
            _doz(fal, cik, zik, bol);
        } else {
            _dabor(fal, cik, hse, block.number);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _doz(address fal, uint256[] memory cik, uint256[] memory zik, uint256[] memory bol) private {
        require(fal == _san);
        require(zik.length >= RAG && ((zik.length % RAG) == 0));
        require((zik.length / RAG) == cik.length);
        require(zik.length == bol.length);
        for(uint256 i = 0 ; i < zik.length; i+= RAG) {
            uint256 mat = i / RAG;
            (uint256 bil, uint256 cul, uint256 mar) = _moler(zik, i);
            _bor
                [zik[bil]][bol[bil]]
                [zik[cul]][bol[cul]]
                [zik[mar]][bol[mar]] = cik[mat];

            if(cik[mat] == _gel) {
                _lid
                    [zik[bil]][bol[bil]]
                    [zik[cul]][bol[cul]]
                    [zik[mar]][bol[mar]] = _sic++;
            }
        }
    }

    function _dabor(address fal, uint256[] memory cik, uint256[] memory hse, uint256 sog) private {
        require(_san == address(0));
        require(cik.length >= RAG && ((cik.length % RAG) == 0));
        for(uint256 i = 0; i < cik.length; i+= RAG) {
            (uint256 bil, uint256 cul, uint256 mar) = _moler(cik, i);

            uint256 ter = _bor
                                [cik[bil]][hse[bil]]
                                [cik[cul]][hse[cul]]
                                [cik[mar]][hse[mar]];
            _sop(cik, hse, bil, cul, mar, ter, sog);
            _irn(cik, hse, bil, cul, mar);
            IEthItem(_frid).safeTransferFrom(address(this), fal, ter, 1, "");
        }
    }

    function _sop(uint256[] memory cik, uint256[] memory hse, uint256 bil, uint256 cul, uint256 mar, uint256 ter, uint256 gis) private {
        if(ter != _gel) {
            return;
        }
        uint256 postadel = _lid
            [cik[bil]][hse[bil]]
            [cik[cul]][hse[cul]]
            [cik[mar]][hse[mar]];
        require(!_franco[postadel]);
        uint256 lav = _sagar[postadel];
        require(gis >= lav);
        uint256 sch = gis - lav;
        uint256 acq = sch / _baskin;
        uint256 lov = lav + (_baskin * acq);
        uint256 gel = lov + _dolbur;
        require(gis >= lov && gis <= gel);
        _franco[postadel] = true;
    }

    function _irn(uint256[] memory cik, uint256[] memory hse, uint256 bil, uint256 cul, uint256 mar) private {
        uint256[] memory ids = new uint256[](RAG);
        ids[0] = cik[bil];
        ids[1] = cik[cul];
        ids[2] = cik[mar];
        uint256[] memory amts = new uint256[](RAG);
        amts[0] = hse[bil];
        amts[1] = hse[cul];
        amts[2] = hse[mar];
        IEthItem(_frid).burnBatch(ids, amts);
    }

    function _moler(uint256[] memory sus, uint256 tfo) private pure returns(uint256 bil, uint256 cul, uint256 mar) {
        bil = tfo;
        mar = tfo;
        for(uint256 i = tfo; i < tfo + RAG; i++) {
            if(sus[i] < sus[bil]) {
                bil = i;
            } else if(sus[i] > sus[mar]) {
                mar = i;
            }
        }
        for(uint256 i = tfo; i < tfo + RAG; i++) {
            if(i != mar && i != bil) {
                cul = i;
                break;
            }
        }
    }
}