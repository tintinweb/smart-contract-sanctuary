// SPDX-License-Identifier: MIT

// @title The library to get the Lenia metadata

/**********************************************
 *                        .                   *
 *                          ,,                *
 *                      ......*#*             *
 *                 .......    ..*%%,          *
 *          .,,****,..             ,#(.       *
 *         .,**((((*,.               .*(.     *
 *          .**((**,,,,,,,             .*,    *
 *        .......,,**(((((((*.          .,,   *
 *       ...      ,*((##%&&&&@&(,        .,.  *
 *       ..        ,((#&&@@@@@@@@&(*.  ..,,.  *
 *    ,. ..          ,#&@@@@@@@@@@@%#(*,,,,.  *
 *      ((,.           *%@@@@&%%%&&%#(((*,,.  *
 *        (&*            *%@@@&&%%##(((**,.   *
 *          (&(           .*(#%%##(((**,,.    *
 *            .((,         .,*(((((**,..      *
 *               .,*,,.....,,,,*,,,..         *
 *                    ..........              *
**********************************************/

pragma solidity ^0.8.6;

library LeniaDescriptor {
    string public constant NAME_PREFIX = "Lenia #";
    string public constant DESCRIPTION = "A beautiful lifeform creature known as Lenia.";
    string public constant EXTERNAL_LINK = "https://lenia.world";

    struct LeniaAttribute {
        uint16 traitType;
        uint16 value;
        string numericalValue;
    }

    struct LeniaParams {
        string m;
        string s;
        bytes cells;
    }

    struct LeniaMetadata {
        bool metadataReady;
        string stringID;
        string imageURL;
        string animationURL;
        LeniaAttribute[] leniaAttributes;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(LeniaMetadata memory metadata, LeniaParams memory leniaParams)
        public
        pure
        returns (string memory)
    {
        bytes memory nameField = abi.encodePacked(
            '"name":"', NAME_PREFIX, metadata.stringID, '"'
        );
        bytes memory descField = abi.encodePacked(
            '"description":"', DESCRIPTION, '"'
        );
        bytes memory extLinkField = abi.encodePacked(
            '"external_link":"', EXTERNAL_LINK, '"'
        );
        bytes memory imgField = abi.encodePacked(
            '"image":"', metadata.imageURL, '"'
        );
        bytes memory animationField = abi.encodePacked(
            '"animation_url":"', metadata.animationURL, '"'
        );
        bytes memory attrField = abi.encodePacked(
            '"attributes":', getAttributesJSON(metadata)
        );
        bytes memory configField = abi.encodePacked(
            '"config": ', getConfigJSON(leniaParams)
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                "data:application/json,",
                abi.encodePacked(
                    "{",
                        nameField, ",",
                        descField, ",",
                        extLinkField, ",",
                        imgField, ",",
                        animationField, ",",
                        attrField, ",",
                        configField,
                    "}"
                )
            )
        );
    }

    /**
     * @notice Get the Lenia attributes
     */
    function getAttributesJSON(LeniaMetadata memory metadata)
        private
        pure
        returns (string memory json)
    {
        string memory output = "[";
        for (uint256 index = 0; index < metadata.leniaAttributes.length; index++) {
            if (bytes(output).length == 1) {
                output = string(abi.encodePacked(
                    output,
                    getAttributeJSON(metadata.leniaAttributes[index])
                ));
            } else {
                output = string(abi.encodePacked(
                    output, ",",
                    getAttributeJSON(metadata.leniaAttributes[index])
                ));
            }

        }
        string memory v;
        if (metadata.leniaAttributes.length > 0){
            v = ',';
        } else {
            v = '';
        }
        output = string(abi.encodePacked(
            output,
            v,
            '{"value": "oui", "trait_type":"On Chain"}',
            "]"
        ));

        return output;
    }

    /**
     * @notice Get one Lenia attribute
     */
    function getAttributeJSON(LeniaAttribute memory attr)
        private
        pure
        returns (string memory json)
    {
        string memory currentTraitType = getTraitType(attr.traitType);
        bytes32 currentTraitTypeHash = keccak256(bytes(currentTraitType));
        string memory currentValue;
        if (currentTraitTypeHash == keccak256(bytes("Colormap"))) {
            currentValue = getColormap(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Family"))) {
            currentValue = getFamily(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Ki"))) {
            currentValue = getKi(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Aura"))) {
            currentValue = getAura(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Weight"))) {
            currentValue = getWeight(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Robustness"))) {
            currentValue = getRobustness(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Avoidance"))) {
            currentValue = getAvoidance(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Velocity"))) {
            currentValue = getVelocity(attr.value);
        } else if (currentTraitTypeHash == keccak256(bytes("Spread"))) {
            currentValue = getSpread(attr.value);
        }
        return string(abi.encodePacked(
            "{",
                '"value":"', currentValue, '",',
                '"trait_type":"', currentTraitType, '",',
                '"numerical_value":', attr.numericalValue,
            "}"
        ));
    }

    /**
     * @notice Get the trait type
     */
    function getTraitType(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[9] memory traitTypes = [
            "Colormap", "Family", "Ki", "Aura", "Weight", "Robustness", "Avoidance", "Velocity", "Spread"
        ];

        return traitTypes[index];
    }

    /**
     * @notice Get the colormap type
     */
     function getColormap(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[10] memory colormaps = [
            "Black White", "Carmine Blue", "Carmine Green", "Cinnamon", "Golden", "Msdos", "Rainbow", "Rainbow_transparent", "Salvia", "White Black"
        ];

        return colormaps[index];
    }

    /**
     * @notice Get the family
     */
    function getFamily(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[12] memory families = [
            "Genesis", "Aquarium", "Terrarium", "Aerium", "Ignis", "Maelstrom", "Amphibium", "Pulsium", "Etherium", "Nexus", "Oscillium", "Kaleidium"
        ];

        return families[index];
    }

    /**
     * @notice Get the ki
     */
    function getKi(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[4] memory kis = [
            "Kiai", "Kiroku", "Kihaku", "Hibiki"
        ];

        return kis[index];
    }

    /**
     * @notice Get the aura
     */
    function getAura(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory auras = [
            "Etheric", "Mental", "Astral", "Celestial", "Spiritual"
        ];

        return auras[index];
    }

    /**
     * @notice Get the weight
     */
    function getWeight(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory weights = [
            "Fly", "Feather", "Welter", "Cruiser", "Heavy"
        ];

        return weights[index];
    }

    /**
     * @notice Get the robustness
     */
    function getRobustness(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory robustnesss = [
            "Aluminium", "Iron", "Steel", "Tungsten", "Vibranium"
        ];

        return robustnesss[index];
    }

    /**
     * @notice Get the avoidance
     */
    function getAvoidance(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory avoidances = [
            "Kawarimi", "Shunshin", "Raiton", "Hiraishin", "Kamui"
        ];

        return avoidances[index];
    }

    /**
     * @notice Get the velocity
     */
    function getVelocity(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory velocitys = [
            "Immovable", "Unrushed", "Swift", "Turbo", "Flash"
        ];

        return velocitys[index];
    }

    /**
     * @notice Get the spread
     */
    function getSpread(uint16 index)
        private
        pure
        returns (string memory)
    {
        string[5] memory spreads = [
            "Demie", "Standard", "Magnum", "Jeroboam", "Balthazar"
        ];

        return spreads[index];
    }

    /**
     * @notice Get the Lenia configuration
     */
    function getConfigJSON(LeniaParams memory leniaParams)
        private
        pure
        returns (string memory json)
    {
        // We can't return cells here because cells are raw bytes which can't be easily converted to utf8 string
        return string(abi.encodePacked(
            "{",
                '"kernels_params":', getKernelParamsJSON(leniaParams), ',',
                '"world_params":', getWorldParamsJSON(),
            "}"
        ));
    }

    /**
     * @notice Get the Lenia world_params
     */
    function getWorldParamsJSON()
        private
        pure
        returns (string memory json)
    {
        return '{"R": 13, "T": 10, "nb_channels": 1, "nb_dims": 2, "scale": 1}';
    }

    /**
     * @notice Get the Lenia kernels_metadata
     */
    function getKernelParamsJSON(LeniaParams memory leniaParams)
        private
        pure
        returns (string memory json)
    {
        return string(abi.encodePacked(
            "[",
                '{"b": "1", "c_in": 0, "c_out": 0, "gf_id": 0, "h": 1, "k_id": 0,',
                '"m": ', leniaParams.m, ',',
                '"q": 4, "r": 1,',
                '"s": ', leniaParams.s, '}',
            "]"
        ));
    }

    function isReady(LeniaMetadata memory metadata, LeniaParams memory leniaParams)
        public
        pure
        returns (bool)
    {
        bool paramsReady = leniaParams.cells.length != 0 && bytes(leniaParams.m).length != 0 && bytes(leniaParams.s).length != 0;

        return metadata.metadataReady && paramsReady;
    }
}

