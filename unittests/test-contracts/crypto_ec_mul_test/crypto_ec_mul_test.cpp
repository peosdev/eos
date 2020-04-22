#include <eosio/eosio.hpp>

extern "C"
{
	__attribute__((eosio_wasm_import))
	int64_t ec_mul(const ec_point*, uint32_t, ec_point*);
}

class[[eosio::contract]] crypto_ec_mul_test : public eosio::contract
{
public:
	using eosio::contract::contract;

	[[eosio::action]] void ecmul() {
		::ec_mul(nullptr, 0, nullptr);
	}
};
