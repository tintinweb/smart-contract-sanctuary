// contracts/DataTypes.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract DataTypes {
    uint256 private x;
    struct DataTypeEntry {
        string val;
        bool isValue;
    }
    mapping(string => DataTypeEntry) public dataTypes;

    // Emitted when the stored data types change
    event ValueChanged(uint256 newValue);

    // Stores the new data types in the contract
    function setDataTypes(uint256 _x) public {
        dataTypes["account"] = DataTypeEntry("account", true);
        dataTypes["account.contact"] = DataTypeEntry("account.contact", true);
        dataTypes["account.contact.city"] = DataTypeEntry(
            "account.contact.city",
            true
        );
        dataTypes["account.contact.country"] = DataTypeEntry(
            "account.contact.country",
            true
        );
        dataTypes["account.contact.email"] = DataTypeEntry(
            "account.contact.email",
            true
        );
        dataTypes["account.contact.phone_number"] = DataTypeEntry(
            "account.contact.phone_number",
            true
        );
        dataTypes["account.contact.postal_code"] = DataTypeEntry(
            "account.contact.postal_code",
            true
        );
        dataTypes["account.contact.state"] = DataTypeEntry(
            "account.contact.state",
            true
        );
        dataTypes["account.contact.street"] = DataTypeEntry(
            "account.contact.street",
            true
        );
        dataTypes["account.payment"] = DataTypeEntry("account.payment", true);
        dataTypes["account.payment.financial_account_number"] = DataTypeEntry(
            "account.payment.financial_account_number",
            true
        );
        dataTypes["system"] = DataTypeEntry("system", true);
        dataTypes["system.authentication"] = DataTypeEntry(
            "system.authentication",
            true
        );
        dataTypes["system.operations"] = DataTypeEntry(
            "system.operations",
            true
        );
        dataTypes["user"] = DataTypeEntry("user", true);
        dataTypes["user.derived"] = DataTypeEntry("user.derived", true);
        dataTypes["user.derived.identifiable"] = DataTypeEntry(
            "user.derived.identifiable",
            true
        );
        dataTypes["user.derived.identifiable.biometric_health"] = DataTypeEntry(
            "user.derived.identifiable.biometric_health",
            true
        );
        dataTypes["user.derived.identifiable.browsing_history"] = DataTypeEntry(
            "user.derived.identifiable.browsing_history",
            true
        );
        dataTypes["user.derived.identifiable.contact"] = DataTypeEntry(
            "user.derived.identifiable.contact",
            true
        );
        dataTypes["user.derived.identifiable.demographic"] = DataTypeEntry(
            "user.derived.identifiable.demographic",
            true
        );
        dataTypes["user.derived.identifiable.gender"] = DataTypeEntry(
            "user.derived.identifiable.gender",
            true
        );
        dataTypes["user.derived.identifiable.location"] = DataTypeEntry(
            "user.derived.identifiable.location",
            true
        );
        dataTypes[
            "user.derived.identifiable.media_consumption"
        ] = DataTypeEntry("user.derived.identifiable.media_consumption", true);
        dataTypes["user.derived.identifiable.non_specific_age"] = DataTypeEntry(
            "user.derived.identifiable.non_specific_age",
            true
        );
        dataTypes["user.derived.identifiable.observed"] = DataTypeEntry(
            "user.derived.identifiable.observed",
            true
        );
        dataTypes["user.derived.identifiable.organization"] = DataTypeEntry(
            "user.derived.identifiable.organization",
            true
        );
        dataTypes["user.derived.identifiable.profiling"] = DataTypeEntry(
            "user.derived.identifiable.profiling",
            true
        );
        dataTypes["user.derived.identifiable.race"] = DataTypeEntry(
            "user.derived.identifiable.race",
            true
        );
        dataTypes["user.derived.identifiable.religious_belief"] = DataTypeEntry(
            "user.derived.identifiable.religious_belief",
            true
        );
        dataTypes["user.derived.identifiable.search_history"] = DataTypeEntry(
            "user.derived.identifiable.search_history",
            true
        );
        dataTypes[
            "user.derived.identifiable.sexual_orientation"
        ] = DataTypeEntry("user.derived.identifiable.sexual_orientation", true);
        dataTypes["user.derived.identifiable.social"] = DataTypeEntry(
            "user.derived.identifiable.social",
            true
        );
        dataTypes["user.derived.identifiable.telemetry"] = DataTypeEntry(
            "user.derived.identifiable.telemetry",
            true
        );
        dataTypes["user.derived.identifiable.unique_id"] = DataTypeEntry(
            "user.derived.identifiable.unique_id",
            true
        );
        dataTypes["user.derived.identifiable.user_sensor"] = DataTypeEntry(
            "user.derived.identifiable.user_sensor",
            true
        );
        dataTypes["user.derived.identifiable.workplace"] = DataTypeEntry(
            "user.derived.identifiable.workplace",
            true
        );
        dataTypes["user.derived.identifiable.device"] = DataTypeEntry(
            "user.derived.identifiable.device",
            true
        );
        dataTypes["user.derived.identifiable.cookie_id"] = DataTypeEntry(
            "user.derived.identifiable.cookie_id",
            true
        );
        dataTypes["user.derived.identifiable.device_id"] = DataTypeEntry(
            "user.derived.identifiable.device_id",
            true
        );
        dataTypes["user.derived.identifiable.ip_address"] = DataTypeEntry(
            "user.derived.identifiable.ip_address",
            true
        );
        dataTypes["user.derived.nonidentifiable"] = DataTypeEntry(
            "user.derived.nonidentifiable",
            true
        );
        dataTypes["user.derived.nonidentifiable.nonsensor"] = DataTypeEntry(
            "user.derived.nonidentifiable.nonsensor",
            true
        );
        dataTypes["user.provided.identifiable"] = DataTypeEntry(
            "user.provided.identifiable",
            true
        );
        dataTypes["user.provided.identifiable.biometric"] = DataTypeEntry(
            "user.provided.identifiable.biometric",
            true
        );
        dataTypes["user.provided.identifiable.childrens"] = DataTypeEntry(
            "user.provided.identifiable.childrens",
            true
        );
        dataTypes[
            "user.provided.identifiable.health_and_medical"
        ] = DataTypeEntry(
            "user.provided.identifiable.health_and_medical",
            true
        );
        dataTypes["user.provided.identifiable.job_title"] = DataTypeEntry(
            "user.provided.identifiable.job_title",
            true
        );
        dataTypes["user.provided.identifiable.name"] = DataTypeEntry(
            "user.provided.identifiable.name",
            true
        );
        dataTypes[
            "user.provided.identifiable.non_specific_age"
        ] = DataTypeEntry("user.provided.identifiable.non_specific_age", true);
        dataTypes[
            "user.provided.identifiable.political_opinion"
        ] = DataTypeEntry("user.provided.identifiable.political_opinion", true);
        dataTypes["user.provided.identifiable.race"] = DataTypeEntry(
            "user.provided.identifiable.race",
            true
        );
        dataTypes[
            "user.provided.identifiable.religious_belief"
        ] = DataTypeEntry("user.provided.identifiable.religious_belief", true);
        dataTypes[
            "user.provided.identifiable.sexual_orientation"
        ] = DataTypeEntry(
            "user.provided.identifiable.sexual_orientation",
            true
        );
        dataTypes["user.provided.identifiable.workplace"] = DataTypeEntry(
            "user.provided.identifiable.workplace",
            true
        );
        dataTypes["user.provided.identifiable.date_of_birth"] = DataTypeEntry(
            "user.provided.identifiable.date_of_birth",
            true
        );
        dataTypes["user.provided.identifiable.gender"] = DataTypeEntry(
            "user.provided.identifiable.gender",
            true
        );
        dataTypes["user.provided.identifiable.genetic"] = DataTypeEntry(
            "user.provided.identifiable.genetic",
            true
        );
        dataTypes["user.provided.identifiable.contact"] = DataTypeEntry(
            "user.provided.identifiable.contact",
            true
        );
        dataTypes["user.provided.identifiable.contact.city"] = DataTypeEntry(
            "user.provided.identifiable.contact.city",
            true
        );
        dataTypes["user.provided.identifiable.contact.country"] = DataTypeEntry(
            "user.provided.identifiable.contact.country",
            true
        );
        dataTypes["user.provided.identifiable.contact.email"] = DataTypeEntry(
            "user.provided.identifiable.contact.email",
            true
        );
        dataTypes[
            "user.provided.identifiable.contact.phone_number"
        ] = DataTypeEntry(
            "user.provided.identifiable.contact.phone_number",
            true
        );
        dataTypes[
            "user.provided.identifiable.contact.postal_code"
        ] = DataTypeEntry(
            "user.provided.identifiable.contact.postal_code",
            true
        );
        dataTypes["user.provided.identifiable.contact.state"] = DataTypeEntry(
            "user.provided.identifiable.contact.state",
            true
        );
        dataTypes["user.provided.identifiable.contact.street"] = DataTypeEntry(
            "user.provided.identifiable.contact.street",
            true
        );
        dataTypes["user.provided.identifiable.credentials"] = DataTypeEntry(
            "user.provided.identifiable.credentials",
            true
        );
        dataTypes[
            "user.provided.identifiable.credentials.biometric_credentials"
        ] = DataTypeEntry(
            "user.provided.identifiable.credentials.biometric_credentials",
            true
        );
        dataTypes[
            "user.provided.identifiable.credentials.password"
        ] = DataTypeEntry(
            "user.provided.identifiable.credentials.password",
            true
        );
        dataTypes["user.provided.identifiable.financial"] = DataTypeEntry(
            "user.provided.identifiable.financial",
            true
        );
        dataTypes[
            "user.provided.identifiable.financial.account_number"
        ] = DataTypeEntry(
            "user.provided.identifiable.financial.account_number",
            true
        );
        dataTypes["user.provided.identifiable.government_id"] = DataTypeEntry(
            "user.provided.identifiable.government_id",
            true
        );
        dataTypes[
            "user.provided.identifiable.government_id.drivers_license_number"
        ] = DataTypeEntry(
            "user.provided.identifiable.government_id.drivers_license_number",
            true
        );
        dataTypes[
            "user.provided.identifiable.government_id.national_identification_number"
        ] = DataTypeEntry(
            "user.provided.identifiable.government_id.national_identification_number",
            true
        );
        dataTypes[
            "user.provided.identifiable.government_id.passport_number"
        ] = DataTypeEntry(
            "user.provided.identifiable.government_id.passport_number",
            true
        );
        dataTypes["user.provided.nonidentifiable"] = DataTypeEntry(
            "user.provided.nonidentifiable",
            true
        );
        //emit ValueChanged(dataTypes);
    }

    function checkDataTypeExistence(string memory _dataType)
        public
        view
        returns (bool)
    {
        if (dataTypes[_dataType].isValue) {
            return true;
        }
        return false;
    }
}