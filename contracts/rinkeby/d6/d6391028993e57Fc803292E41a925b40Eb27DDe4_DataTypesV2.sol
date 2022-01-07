// contracts/DataTypesV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract DataTypesV2 {
    uint256 private x;
    string[] private dataTypes;

    // Emitted when the stored data types change
    event ValueChanged(uint256 newValue);

    // Stores the new data types in the contract
    function setDataTypes(uint256 _x) public {
        dataTypes = [
            "account",
            "account.contact",
            "account.contact.city",
            "account.contact.country",
            "account.contact.email",
            "account.contact.phone_number",
            "account.contact.postal_code",
            "account.contact.state",
            "account.contact.street",
            "account.payment",
            "account.payment.financial_account_number",
            "system",
            "system.authentication",
            "system.operations",
            "user",
            "user.derived",
            "user.derived.identifiable",
            "user.derived.identifiable.biometric_health",
            "user.derived.identifiable.browsing_history",
            "user.derived.identifiable.contact",
            "user.derived.identifiable.demographic",
            "user.derived.identifiable.gender",
            "user.derived.identifiable.location",
            "user.derived.identifiable.media_consumption",
            "user.derived.identifiable.non_specific_age",
            "user.derived.identifiable.observed",
            "user.derived.identifiable.organization",
            "user.derived.identifiable.profiling",
            "user.derived.identifiable.race",
            "user.derived.identifiable.religious_belief",
            "user.derived.identifiable.search_history",
            "user.derived.identifiable.sexual_orientation",
            "user.derived.identifiable.social",
            "user.derived.identifiable.telemetry",
            "user.derived.identifiable.unique_id",
            "user.derived.identifiable.user_sensor",
            "user.derived.identifiable.workplace",
            "user.derived.identifiable.device",
            "user.derived.identifiable.cookie_id",
            "user.derived.identifiable.device_id",
            "user.derived.identifiable.ip_address",
            "user.derived.nonidentifiable",
            "user.derived.nonidentifiable.nonsensor",
            "user.provided.identifiable",
            "user.provided.identifiable.biometric",
            "user.provided.identifiable.childrens",
            "user.provided.identifiable.health_and_medical",
            "user.provided.identifiable.job_title",
            "user.provided.identifiable.name",
            "user.provided.identifiable.non_specific_age",
            "user.provided.identifiable.political_opinion",
            "user.provided.identifiable.race",
            "user.provided.identifiable.religious_belief",
            "user.provided.identifiable.sexual_orientation",
            "user.provided.identifiable.workplace",
            "user.provided.identifiable.date_of_birth",
            "user.provided.identifiable.gender",
            "user.provided.identifiable.genetic",
            "user.provided.identifiable.contact",
            "user.provided.identifiable.contact.city",
            "user.provided.identifiable.contact.country",
            "user.provided.identifiable.contact.email",
            "user.provided.identifiable.contact.phone_number",
            "user.provided.identifiable.contact.postal_code",
            "user.provided.identifiable.contact.state",
            "user.provided.identifiable.contact.street",
            "user.provided.identifiable.credentials",
            "user.provided.identifiable.credentials.biometric_credentials",
            "user.provided.identifiable.credentials.password",
            "user.provided.identifiable.financial",
            "user.provided.identifiable.financial.account_number",
            "user.provided.identifiable.government_id",
            "user.provided.identifiable.government_id.drivers_license_number",
            "user.provided.identifiable.government_id.national_identification_number",
            "user.provided.identifiable.government_id.passport_number",
            "user.provided.nonidentifiable"
        ];
        //emit ValueChanged(dataTypes);
    }

    function retrieveDataTypes() public view returns (string[] memory) {
        return dataTypes;
    }
}