import logging
import os

LOG_FILE_PATH = "/opt/webapp/webapp.log"
os.makedirs(os.path.dirname(LOG_FILE_PATH), exist_ok=True)

logging.basicConfig(
    filename=LOG_FILE_PATH,
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s',
    filemode='a'
)

logger = logging.getLogger(__name__)
