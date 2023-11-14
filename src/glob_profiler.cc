#include "glob_profiler.h"

nlohmann::json GlobalProfiler::_state;
std::vector<Callback> GlobalProfiler::_registered;
std::vector<MutateState> GlobalProfiler::_mutations;
unsigned GlobalProfiler::PROFILER_INTERVAL = getenv("PROFILER_INTERVAL") ? std::atoi(getenv("PROFILER_INTERVAL")) : 10000;
bool GlobalProfiler::DEBUG_PROFILER = getenv("DEBUG_PROFILER") ? getenv("DEBUG_PROFILER")[0] == '1' : false;
const char * GlobalProfiler::PROFILER_LOG_PATH = getenv("PROFILER_LOG_PATH") ? getenv("PROFILER_LOG_PATH") : "log.json";
std::ofstream GlobalProfiler::logFile(PROFILER_LOG_PATH);
uint64_t GlobalProfiler::_invocations = 0;
GlobalProfiler profile;