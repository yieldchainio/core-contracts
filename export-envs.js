import { exec } from "child_process";
import dotenv from "dotenv";
dotenv.config();

exec("source .env && export $(cut -d= -f1 < .env)");
