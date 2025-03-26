import logging
import os
from statsd import StatsClient

# --- Logging Setup ---
LOG_FILE_PATH = "/opt/webapp/webapp.log"
os.makedirs(os.path.dirname(LOG_FILE_PATH), exist_ok=True)

logging.basicConfig(
    filename=LOG_FILE_PATH,
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s',
    filemode='a'
)

logger = logging.getLogger(__name__)

# --- StatsD Setup ---
statsd = StatsClient(host='localhost', port=8125, prefix='webapp')